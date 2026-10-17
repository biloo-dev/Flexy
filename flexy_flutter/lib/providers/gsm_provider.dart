import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/gsm_service.dart';
import '../services/tts_service.dart';

class GsmConnectedSim {
  final String port;
  final int operatorId; // 1: Djezzy, 2: Mobilis, 3: Ooredoo
  final String operatorName; // 'Djezzy', 'Mobilis', 'Ooredoo'
  String iccid;
  String phoneNumber;
  String balance;
  int signalLevel; // 0..4
  int rawRssi;
  bool isRefreshing;
  bool isDefault;

  GsmConnectedSim({
    required this.port,
    required this.operatorId,
    required this.operatorName,
    this.iccid = '',
    this.phoneNumber = '',
    this.balance = '--- DA',
    this.signalLevel = 0,
    this.rawRssi = 0,
    this.isRefreshing = false,
    this.isDefault = false,
  });

  String get displayName => phoneNumber.isNotEmpty && !phoneNumber.contains('Non')
      ? phoneNumber
      : 'SIM ($port)';

  String get maskedPhone {
    if (phoneNumber.length >= 10) {
      return '${phoneNumber.substring(0, 4)} ▪▪ ▪▪ ${phoneNumber.substring(8)}';
    }
    return operatorId == 1
        ? '07XX ▪▪ ▪▪ 12'
        : (operatorId == 2 ? '06XX ▪▪ ▪▪ 67' : '05XX ▪▪ ▪▪ 89');
  }
}

class GsmProvider with ChangeNotifier {
  List<String> _availablePorts = [];
  bool _isScanning = false;
  bool _isPolling = false;
  Timer? _autoDetectTimer;
  final Set<String> _knownPorts = {};
  String? _lastUsbEventMessage;

  // Dynamic multi-SIM collection
  final List<GsmConnectedSim> _connectedSims = [];

  List<GsmConnectedSim> get connectedSimList => List.unmodifiable(_connectedSims);

  List<GsmConnectedSim> getSimsForOperator(int operatorId) {
    return _connectedSims.where((s) => s.operatorId == operatorId).toList();
  }

  GsmConnectedSim? getDefaultSimForOperator(int operatorId) {
    final sims = getSimsForOperator(operatorId);
    if (sims.isEmpty) return null;
    return sims.firstWhere((s) => s.isDefault, orElse: () => sims.first);
  }

  void setDefaultSim(String port) {
    final match = _connectedSims.where((s) => s.port == port).toList();
    if (match.isEmpty) return;
    final opId = match.first.operatorId;
    for (var sim in _connectedSims) {
      if (sim.operatorId == opId) {
        sim.isDefault = (sim.port == port);
      }
    }
    _syncLegacyMaps();
    notifyListeners();
  }

  void clearDefaultSim(int operatorId) {
    for (var sim in _connectedSims) {
      if (sim.operatorId == operatorId) {
        sim.isDefault = false;
      }
    }
    _syncLegacyMaps();
    notifyListeners();
  }

  // Legacy Single-Slot Maps for Backward Compatibility
  final Map<int, String> _operatorBalances = {
    1: 'Non connecté',
    2: 'Non connecté',
    3: 'Non connecté',
  };

  final Map<int, bool> _connectedStatus = {
    1: false,
    2: false,
    3: false,
  };

  final Map<int, int> _signalLevels = {
    1: 0,
    2: 0,
    3: 0,
  };

  final Map<int, String> _operatorComPorts = {
    1: '--',
    2: '--',
    3: '--',
  };

  final Map<int, String> _simPhoneMasks = {
    1: '07XX ▪▪ ▪▪ 12',
    2: '06XX ▪▪ ▪▪ 67',
    3: '05XX ▪▪ ▪▪ 89',
  };

  final Map<int, String> _simIccids = {
    1: '',
    2: '',
    3: '',
  };

  final Map<int, String> _simPhoneNumbers = {
    1: '',
    2: '',
    3: '',
  };

  final Map<int, bool> _isRefreshing = {
    1: false,
    2: false,
    3: false,
  };

  final Map<int, int> _rawRssiValues = {
    1: 0,
    2: 0,
    3: 0,
  };

  final Set<String> _initializedModemPorts = {};

  List<String> get availablePorts => _availablePorts;
  bool get isScanning => _isScanning;
  String? get lastUsbEventMessage => _lastUsbEventMessage;
  Map<int, String> get operatorBalances => _operatorBalances;
  Map<int, bool> get connectedStatus => _connectedStatus;
  Map<int, int> get signalLevels => _signalLevels;
  Map<int, String> get operatorComPorts => _operatorComPorts;
  Map<int, String> get simPhoneMasks => _simPhoneMasks;
  Map<int, String> get simIccids => _simIccids;
  Map<int, String> get simPhoneNumbers => _simPhoneNumbers;
  Map<int, bool> get isRefreshing => _isRefreshing;
  Map<int, int> get rawRssiValues => _rawRssiValues;

  /// Start automatic background polling (every 5 seconds for signal / hardware scan)
  void startAutoDetection() {
    _autoDetectTimer?.cancel();
    _autoDetectTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollOsPorts();
    });
    _pollOsPorts();
  }

  void stopAutoDetection() {
    _autoDetectTimer?.cancel();
  }

  Future<void> refreshPorts() async {
    _isScanning = true;
    _initializedModemPorts.clear();
    notifyListeners();
    await _pollOsPorts();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> _pollOsPorts() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final currentPorts = await GsmService.instance.getAvailablePortsFromOs();

      final List<String> addedPorts = [];
      for (var p in currentPorts) {
        if (!_knownPorts.contains(p)) {
          addedPorts.add(p);
        }
      }

      final List<String> removedPorts = [];
      for (var p in _knownPorts) {
        if (!currentPorts.contains(p)) {
          removedPorts.add(p);
        }
      }

      // Process POP (Unplugged / Removed) events
      if (removedPorts.isNotEmpty) {
        for (var p in removedPorts) {
          _knownPorts.remove(p);
          _initializedModemPorts.remove(p);
          _connectedSims.removeWhere((s) => s.port == p);
          _lastUsbEventMessage = '❌ POP: Clé USB GSM déconnectée ($p)';
          TtsService.instance.speak('Clé USB déconnectée du port $p.');
        }
      }

      // Process PUT (Plugged / Inserted) events
      if (addedPorts.isNotEmpty) {
        for (var p in addedPorts) {
          _knownPorts.add(p);
          _lastUsbEventMessage = '🔌 PUT: Nouvelle clé USB GSM insérée ($p)';
        }
      }

      _availablePorts = currentPorts;

      // Prune disconnected SIMs
      _connectedSims.removeWhere((sim) => !currentPorts.contains(sim.port));

      for (var portName in currentPorts) {
        // Fast probe: check if port is responsive to AT commands before considering it a GSM SIM
        final isResponsive = await GsmService.instance.testPortAtResponse(portName);
        if (!isResponsive) {
          debugPrint('⚠️ [GSM] Port $portName ne répond pas aux commandes AT. Ignoré.');
          _connectedSims.removeWhere((s) => s.port == portName);
          continue;
        }

        final existingIndex = _connectedSims.indexWhere((s) => s.port == portName);

        if (existingIndex == -1) {
          final opId = await _detectOperatorForPort(portName) ?? 2;
          final opName = (opId == 1) ? 'DJEZZY' : ((opId == 2) ? 'MOBILIS' : 'OOREDOO');

          final sim = GsmConnectedSim(
            port: portName,
            operatorId: opId,
            operatorName: opName,
          );

          // Double check existence to prevent race duplicate insertion
          if (!_connectedSims.any((s) => s.port == portName)) {
            _connectedSims.add(sim);
          }
          _initializedModemPorts.add(portName);

          // Fetch SIM details & balance
          await _querySimDetails(sim);
        } else {
          final sim = _connectedSims[existingIndex];
          // Periodically update signal
          await _querySimSignal(sim);
        }
      }

      // Deduplicate by port
      final seenPorts = <String>{};
      _connectedSims.retainWhere((s) => seenPorts.add(s.port));

      // Deduplicate by ICCID if non-empty (prevents multiple COM ports mapping to same SIM card)
      final seenIccids = <String>{};
      _connectedSims.retainWhere((s) {
        if (s.iccid.isNotEmpty && !s.iccid.contains('Non') && !s.iccid.contains('Lecture')) {
          return seenIccids.add(s.iccid);
        }
        return true;
      });

      _syncLegacyMaps();
    } finally {
      _isPolling = false;
      notifyListeners();
    }
  }

  void _syncLegacyMaps() {
    for (int opId in [1, 2, 3]) {
      final defaultSim = getDefaultSimForOperator(opId);
      if (defaultSim != null) {
        _connectedStatus[opId] = true;
        _operatorComPorts[opId] = defaultSim.port;
        _operatorBalances[opId] = defaultSim.balance;
        _signalLevels[opId] = defaultSim.signalLevel;
        _rawRssiValues[opId] = defaultSim.rawRssi;
        _simIccids[opId] = defaultSim.iccid;
        _simPhoneNumbers[opId] = defaultSim.phoneNumber;
        _simPhoneMasks[opId] = defaultSim.maskedPhone;
        _isRefreshing[opId] = defaultSim.isRefreshing;
      } else {
        _connectedStatus[opId] = false;
        _operatorComPorts[opId] = '--';
        _operatorBalances[opId] = 'Non connecté';
        _signalLevels[opId] = 0;
        _rawRssiValues[opId] = 0;
        _simIccids[opId] = '';
        _simPhoneNumbers[opId] = '';
        _isRefreshing[opId] = false;
      }
    }
  }

  Future<void> _querySimDetails(GsmConnectedSim sim) async {
    try {
      final iccid = await GsmService.instance.querySimIccid(sim.port);
      sim.iccid = iccid.isNotEmpty ? iccid : 'Non disponible';

      final phone = await GsmService.instance.querySimPhoneNumber(sim.operatorId, sim.port);
      sim.phoneNumber = phone.isNotEmpty ? phone : 'Non disponible';

      await _querySimBalance(sim);
    } catch (_) {}
  }

  Future<int?> _detectOperatorForPort(String portName) async {
    try {
      final copsResp = await GsmService.instance.sendRawAtCommand(portName, 'AT+COPS?', timeoutSeconds: 3, showLog: false);
      final lowerCops = copsResp.toLowerCase();
      if (lowerCops.contains('djezzy') || lowerCops.contains('60502') || lowerCops.contains('ota')) {
        return 1; // Djezzy
      } else if (lowerCops.contains('mobilis') || lowerCops.contains('60501')) {
        return 2; // Mobilis
      } else if (lowerCops.contains('ooredoo') || lowerCops.contains('60503') || lowerCops.contains('nedjma')) {
        return 3; // Ooredoo
      }
    } catch (_) {}
    return null;
  }

  Future<void> _querySimSignal(GsmConnectedSim sim) async {
    try {
      final csqResp = await GsmService.instance.sendRawAtCommand(sim.port, 'AT+CSQ', timeoutSeconds: 3, showLog: false);
      final regCsq = RegExp(r'\+CSQ:\s*([0-9]+)', caseSensitive: false);
      final match = regCsq.firstMatch(csqResp);
      if (match != null) {
        final rssi = int.tryParse(match.group(1) ?? '0') ?? 0;
        sim.rawRssi = rssi;

        int bars = 0;
        if (rssi == 99 || rssi == 0) {
          bars = 0;
        } else if (rssi >= 21) {
          bars = 4;
        } else if (rssi >= 14) {
          bars = 3;
        } else if (rssi >= 7) {
          bars = 2;
        } else if (rssi > 0) {
          bars = 1;
        } else {
          bars = 0;
        }

        sim.signalLevel = bars;
      }
    } catch (_) {}
  }

  Future<void> _querySimBalance(GsmConnectedSim sim) async {
    int codeSolde = (sim.operatorId == 1) ? 710 : ((sim.operatorId == 2) ? 222 : 200);
    try {
      final optSetting = await DatabaseHelper.instance.getSettingsByOperator(sim.operatorId);
      if (optSetting != null) {
        codeSolde = optSetting.codeSolde;
      }
    } catch (_) {}

    final ussdCmd = '*$codeSolde#';
    String ussdResp = await GsmService.instance.sendRawAtCommand(sim.port, 'AT+CUSD=1,"$ussdCmd",15', timeoutSeconds: 6);

    if (ussdResp.contains('TIMEOUT') || ussdResp.contains('ERREUR') || !ussdResp.contains('Solde')) {
      ussdResp = await GsmService.instance.sendRawAtCommand(sim.port, 'AT+CUSD=1,"$ussdCmd"', timeoutSeconds: 6);
    }

    final parsed = parseBalanceText(ussdResp);
    if (parsed.isNotEmpty) {
      sim.balance = parsed;
    }
  }

  Future<void> refreshSim(String port) async {
    final simIndex = _connectedSims.indexWhere((s) => s.port == port);
    if (simIndex == -1) return;
    final sim = _connectedSims[simIndex];
    sim.isRefreshing = true;
    _syncLegacyMaps();
    notifyListeners();

    try {
      await _querySimSignal(sim);
      await _querySimBalance(sim);
      await _querySimDetails(sim);
    } finally {
      sim.isRefreshing = false;
      _syncLegacyMaps();
      notifyListeners();
    }
  }

  Future<void> refreshOperatorModem(int operatorId) async {
    final defaultSim = getDefaultSimForOperator(operatorId);
    if (defaultSim != null) {
      await refreshSim(defaultSim.port);
    } else {
      await _pollOsPorts();
    }
  }

  /// Helper to extract numeric balance or formatted text from USSD response
  String parseBalanceText(String response) {
    if (response.isEmpty || response.contains('TIMEOUT') || response.contains('ERREUR')) {
      return '';
    }

    final regSolde = RegExp(r'Solde\s*:?\s*([0-9]+(?:[.,][0-9]+)?)', caseSensitive: false);
    final matchSolde = regSolde.firstMatch(response);
    if (matchSolde != null) {
      final valStr = matchSolde.group(1);
      if (valStr != null) {
        final val = double.tryParse(valStr.replaceAll(',', '.'));
        if (val != null) {
          return '${val.toStringAsFixed(0)} DA';
        }
      }
    }

    final regDa = RegExp(r'([0-9]+(?:[.,][0-9]+)?)\s*(?:DA|DZD)', caseSensitive: false);
    final matchDa = regDa.firstMatch(response);
    if (matchDa != null) {
      final valStr = matchDa.group(1);
      if (valStr != null) {
        final val = double.tryParse(valStr.replaceAll(',', '.'));
        if (val != null) {
          return '${val.toStringAsFixed(0)} DA';
        }
      }
    }

    return '';
  }

  void updateBalance(int operatorId, String newBalance) {
    final def = getDefaultSimForOperator(operatorId);
    if (def != null) {
      def.balance = newBalance;
    }
    _operatorBalances[operatorId] = newBalance;
    notifyListeners();
  }

  void toggleConnection(int operatorId) {
    final nextState = !(_connectedStatus[operatorId] ?? false);
    _connectedStatus[operatorId] = nextState;
    if (!nextState) {
      _connectedSims.removeWhere((s) => s.operatorId == operatorId);
    } else {
      final port = operatorId == 1 ? 'COM5' : (operatorId == 2 ? 'COM3' : 'COM7');
      final sim = GsmConnectedSim(
        port: port,
        operatorId: operatorId,
        operatorName: operatorId == 1 ? 'DJEZZY' : (operatorId == 2 ? 'MOBILIS' : 'OOREDOO'),
        signalLevel: 4,
        balance: operatorId == 1 ? '8 750 DA' : (operatorId == 2 ? '12 450 DA' : '6 300 DA'),
        isDefault: false,
      );
      _connectedSims.add(sim);
    }
    _syncLegacyMaps();
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoDetection();
    super.dispose();
  }
}
