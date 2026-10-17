import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client_model.dart';
import '../models/historique_model.dart';
import '../models/settings_model.dart';
import '../models/user_model.dart';
import '../models/paiement_dette_model.dart';
import '../services/gsm_service.dart';
import '../services/tts_service.dart';

class FlexyProvider with ChangeNotifier {
  List<HistoriqueModel> _historiqueList = [];
  List<ClientModel> _clientList = [];
  List<PaiementDetteModel> _paiementDetteList = [];
  bool _isLoading = false;
  String? _lastResponse;

  int _selectedOperatorFilter = 0; // 0: All, 1: Djezzy, 2: Mobilis, 3: Ooredoo
  String _selectedHistFilter = "2"; // 1: Received, 2: Sent
  String _searchQuery = '';

  List<HistoriqueModel> get historiqueList {
    return _historiqueList.where((h) {
      if (_selectedOperatorFilter != 0 && h.operateur != _selectedOperatorFilter) {
        return false;
      }
      if (_selectedHistFilter == "1" && h.type) return false;
      if (_selectedHistFilter == "2" && !h.type) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesNum = h.numero.contains(query);
        final matchesClient = (h.clientName ?? '').toLowerCase().contains(query);
        return matchesNum || matchesClient;
      }
      return true;
    }).toList();
  }

  List<HistoriqueModel> get rawHistoriqueList => _historiqueList;
  List<ClientModel> get clientList => _clientList;
  List<PaiementDetteModel> get paiementDetteList => _paiementDetteList;
  bool get isLoading => _isLoading;
  String? get lastResponse => _lastResponse;
  int get selectedOperatorFilter => _selectedOperatorFilter;
  String get selectedHistFilter => _selectedHistFilter;

  void setOperatorFilter(int op) {
    _selectedOperatorFilter = op;
    notifyListeners();
  }

  void setHistFilter(String filter) {
    _selectedHistFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _historiqueList = await DatabaseHelper.instance.getAllHistoriques();
    _clientList = await DatabaseHelper.instance.getAllClients();
    _paiementDetteList = await DatabaseHelper.instance.getAllPaiementsDette();

    _isLoading = false;
    notifyListeners();
  }

  double get todayTotalRevenue {
    final now = DateTime.now();
    return _historiqueList
        .where((h) =>
            h.createdAt.year == now.year &&
            h.createdAt.month == now.month &&
            h.createdAt.day == now.day &&
            h.status)
        .fold(0.0, (sum, item) => sum + item.somme);
  }

  double get totalClientCredit {
    return _clientList.fold(0.0, (sum, c) => sum + c.credit);
  }

  Future<bool> sendFlexy({
    required String phoneNumber,
    required double price,
    required SettingsModel settings,
    int? clientId,
    int? userId,
    String? userFullname,
    bool isCredit = false,
  }) async {
    _isLoading = true;
    _lastResponse = null;
    notifyListeners();

    try {
      final operatorId = GsmService.instance.detectOperator(phoneNumber);
      final ussdCmd = GsmService.instance.buildFlexyUssd(operatorId, phoneNumber, price, settings);

      final responseText = await GsmService.instance.executeUssd(settings.comPort, ussdCmd);
      _lastResponse = responseText;

      // Auto-resolve clientId from phone number if not explicitly specified
      int? resolvedClientId = clientId;
      String? resolvedClientName;

      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      final matchedClient = _clientList.firstWhere(
        (c) => c.numeroPhoneList.any((p) {
          final pClean = p.replaceAll(RegExp(r'\s+'), '');
          return pClean.endsWith(cleanPhone) || cleanPhone.endsWith(pClean);
        }),
        orElse: () => ClientModel(nomPrenom: '', numeroPhoneList: []),
      );

      if (matchedClient.id != null) {
        resolvedClientId = matchedClient.id;
        resolvedClientName = matchedClient.nomPrenom;
      }

      final hist = HistoriqueModel(
        operateur: operatorId,
        numero: phoneNumber,
        somme: price,
        restSomme: isCredit ? price : 0.0,
        sommePayee: isCredit ? 0.0 : price,
        reponse: responseText,
        type: true, // Sent
        status: true,
        credit: isCredit,
        idClient: resolvedClientId,
        idUser: userId,
      );

      await DatabaseHelper.instance.insertHistorique(hist);

      final currentClientDebt = matchedClient.id != null ? matchedClient.credit : 0.0;
      final newClientDebt = isCredit ? (currentClientDebt + price) : currentClientDebt;

      if (isCredit && resolvedClientId != null) {
        // Credit transaction -> Add amount to Client debt
        final clientIndex = _clientList.indexWhere((c) => c.id == resolvedClientId);
        if (clientIndex != -1) {
          final client = _clientList[clientIndex];
          final updatedClient = ClientModel(
            id: client.id,
            nomPrenom: client.nomPrenom,
            fidel: client.fidel,
            type: client.type,
            numeroPhoneList: client.numeroPhoneList,
            credit: newClientDebt,
          );
          await DatabaseHelper.instance.updateClient(updatedClient);
        }
      } else {
        // Default Cash transaction -> Add revenue to Tresorerie (Cash Drawer)
        await DatabaseHelper.instance.insertTresorerie(
          somme: price,
          idUser: userId ?? 1,
          idClient: resolvedClientId,
          note: 'Flexy Cash -> ${resolvedClientName ?? phoneNumber}',
        );
      }

      // Save Audit Log (PaiementDetteModel) so ANY flexy transaction appears in "سجل التسديدات والمستلمين"
      final auditLog = PaiementDetteModel(
        idClient: resolvedClientId ?? 0,
        idUser: userId ?? 1,
        userFullname: userFullname ?? 'Admin',
        nomClient: resolvedClientName ?? (phoneNumber.isNotEmpty ? phoneNumber : 'زبون غير مسجل'),
        montant: price,
        ancienCredit: currentClientDebt,
        nouveauCredit: newClientDebt,
        note: isCredit ? 'فليكسي آجل (دين)' : 'فليكسي مدفوع (كاش)',
      );
      await DatabaseHelper.instance.insertPaiementDette(auditLog);

      // Voice notification TTS
      final operatorName = operatorId == 1 ? 'Djezzy' : (operatorId == 2 ? 'Mobilis' : 'Ooredoo');
      final targetName = resolvedClientName != null ? 'pour $resolvedClientName' : 'vers $operatorName';
      await TtsService.instance.speak("Transfert de $price Dinars $targetName effectué avec succès");

      await loadData();
      return true;
    } catch (e) {
      _lastResponse = 'Erreur lors du transfert: $e';
      
      try {
        final operatorId = GsmService.instance.detectOperator(phoneNumber);
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
        final matchedClient = _clientList.firstWhere(
          (c) => c.numeroPhoneList.any((p) {
            final pClean = p.replaceAll(RegExp(r'\s+'), '');
            return pClean.endsWith(cleanPhone) || cleanPhone.endsWith(pClean);
          }),
          orElse: () => ClientModel(nomPrenom: '', numeroPhoneList: []),
        );

        final failedHist = HistoriqueModel(
          operateur: operatorId,
          numero: phoneNumber,
          somme: price,
          restSomme: isCredit ? price : 0.0,
          sommePayee: 0.0,
          reponse: 'Échec: $e',
          type: true, // Sent
          status: false, // FAILED
          credit: isCredit,
          idClient: matchedClient.id ?? clientId,
          idUser: userId,
          clientName: matchedClient.nomPrenom.isNotEmpty ? matchedClient.nomPrenom : null,
        );
        await DatabaseHelper.instance.insertHistorique(failedHist);
        await loadData();
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteHistorique(int id) async {
    await DatabaseHelper.instance.deleteHistorique(id);
    await loadData();
  }

  Future<void> saveClient(ClientModel client) async {
    if (client.id == null) {
      await DatabaseHelper.instance.insertClient(client);
    } else {
      await DatabaseHelper.instance.updateClient(client);
    }
    await loadData();
  }

  /// Process customer debt payment (partial or full) with cashier audit logging
  Future<bool> payClientCredit({
    required ClientModel client,
    required double amountPaid,
    required UserModel user,
    String? note,
  }) async {
    if (client.id == null || amountPaid <= 0) return false;

    final ancienCredit = client.credit;
    final newCredit = (ancienCredit - amountPaid).clamp(0.0, double.infinity);

    final updatedClient = ClientModel(
      id: client.id,
      nomPrenom: client.nomPrenom,
      fidel: client.fidel,
      type: client.type,
      numeroPhoneList: client.numeroPhoneList,
      credit: newCredit,
    );

    // 1. Update Client debt in SQLite
    await DatabaseHelper.instance.updateClient(updatedClient);

    // 2. Save Payment Audit Log (who received the money)
    final p = PaiementDetteModel(
      idClient: client.id!,
      idUser: user.id ?? 1,
      userFullname: user.fullName,
      nomClient: client.nomPrenom,
      montant: amountPaid,
      ancienCredit: ancienCredit,
      nouveauCredit: newCredit,
      note: note,
    );
    await DatabaseHelper.instance.insertPaiementDette(p);

    // 3. Record in Tresorerie cash drawer
    await DatabaseHelper.instance.insertTresorerie(
      somme: amountPaid,
      idUser: user.id ?? 1,
      idClient: client.id,
      note: 'Règlement dette par ${client.nomPrenom}',
    );

    // 4. Voice notification TTS
    await TtsService.instance.speak(
      "Paiement de ${amountPaid.toInt()} Dinars reçu de ${client.nomPrenom} par ${user.fullName}",
    );

    await loadData();
    return true;
  }
}
