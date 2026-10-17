import 'dart:async';
import 'package:flutter/material.dart';
import '../models/license_model.dart';
import '../services/license_service.dart';
import '../services/license_socket_service.dart';
import 'gsm_provider.dart';

class LicenseProvider with ChangeNotifier {
  final LicenseSocketService _socketService = LicenseSocketService.instance;

  // Legacy Single-Slot Maps for Backward Compatibility
  final Map<int, bool> _isSimActivated = {
    1: false,
    2: false,
    3: false,
  };

  final Map<int, String> _simStatusLabels = {
    1: 'غير مفعلة',
    2: 'غير مفعلة',
    3: 'غير مفعلة',
  };

  final Map<int, String> _simSerialCodes = {
    1: '',
    2: '',
    3: '',
  };

  final Map<int, DateTime?> _simExpiryDates = {
    1: null,
    2: null,
    3: null,
  };

  // Dynamic Per-ICCID Activation State
  final Map<String, bool> _simActivationByIccid = {};
  final Map<String, String> _simStatusByIccid = {};
  final Map<String, String> _simSerialByIccid = {};
  final Map<String, DateTime?> _simExpiryByIccid = {};

  bool _isChecking = false;
  bool _isOnline = false;
  bool _showAdminOnlineReminder = false;
  String? _adminNoticeMessage;
  String? _lastError;
  GsmProvider? _cachedGsmProvider;
  bool _isInitialized = false;
  String _lastReportedModemsSignature = '';

  Map<int, bool> get isSimActivated => _isSimActivated;
  Map<int, String> get simStatusLabels => _simStatusLabels;
  Map<int, String> get simSerialCodes => _simSerialCodes;
  Map<int, DateTime?> get simExpiryDates => _simExpiryDates;
  bool get isChecking => _isChecking;
  bool get isOnline => _isOnline;
  bool get isSocketConnected => _socketService.isConnected;
  SocketConnectionState get socketState => _socketService.connectionState;
  bool get showAdminOnlineReminder => _showAdminOnlineReminder;
  String? get adminNoticeMessage => _adminNoticeMessage;
  int get offlineHoursRemaining => 72;
  String? get lastError => _lastError;

  bool isIccidActivated(String iccid) {
    final clean = iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (clean.isEmpty || clean.contains('Non') || clean.contains('Lecture')) return false;
    return _simActivationByIccid[clean] ?? false;
  }

  String getStatusLabelForIccid(String iccid) {
    final clean = iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (clean.isEmpty || clean.contains('Non') || clean.contains('Lecture')) return 'غير متصلة 🔌';
    return _simStatusByIccid[clean] ?? 'غير مفعلة';
  }

  String getSerialForIccid(String iccid) {
    final clean = iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (clean.isEmpty || clean.contains('Non') || clean.contains('Lecture')) return '';
    return _simSerialByIccid[clean] ?? '';
  }

  DateTime? getExpiryForIccid(String iccid) {
    final clean = iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (clean.isEmpty || clean.contains('Non') || clean.contains('Lecture')) return null;
    return _simExpiryByIccid[clean];
  }

  String getOperatorCode(int operatorId) {
    switch (operatorId) {
      case 1:
        return 'DJZ';
      case 2:
        return 'MOB';
      case 3:
        return 'OOR';
      default:
        return 'DJZ';
    }
  }

  String getOperatorName(int operatorId) {
    switch (operatorId) {
      case 1:
        return 'Djezzy';
      case 2:
        return 'Mobilis';
      case 3:
        return 'Ooredoo';
      default:
        return 'Operator $operatorId';
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  /// Verifies all SIM cards OFFLINE on app startup and starts real-time Socket.IO connection in background
  Future<void> checkSimsOnStartup(GsmProvider gsmProvider) async {
    _cachedGsmProvider = gsmProvider;
    _isChecking = true;
    _lastError = null;
    notifyListeners();

    // 1. Offline-First Verification: Immediately verify local serials against SIM ICCIDs
    await _loadAndVerifyLocalLicenses(gsmProvider);

    // 2. Setup Socket.IO Callbacks for background sync & live admin push events
    _setupSocketCallbacks(gsmProvider);

    // 3. Connect via Real-Time Socket.IO Gateway in background
    final deviceUuid = await LicenseService.instance.getOrCreateDeviceUuid();
    final fingerprint = LicenseService.instance.getHardwareFingerprint();
    final modems = _buildModemsPayload(gsmProvider);
    _lastReportedModemsSignature = modems.map((m) => '${m['port']}_${m['iccid']}_${m['operator']}').join('|');

    _socketService.connect(
      deviceUuid: deviceUuid,
      deviceFingerprint: fingerprint,
      modems: modems,
    );

    // 4. Hook hardware change listener to notify server only on real physical USB change
    if (!_isInitialized) {
      _isInitialized = true;
      gsmProvider.addListener(() {
        _onGsmHardwareChanged(gsmProvider);
      });
    }

    _isChecking = false;
    notifyListeners();
  }

  void _setupSocketCallbacks(GsmProvider gsmProvider) {
    _socketService.onStateReceived = (state) {
      _handleServerState(state, gsmProvider);
    };

    _socketService.onErrorReceived = (errorMsg) {
      _lastError = errorMsg;
      notifyListeners();
    };

    _socketService.onConnectionStateChanged = (state) {
      if (state == SocketConnectionState.connected) {
        _isOnline = true;
        _showAdminOnlineReminder = false;
        _adminNoticeMessage = null;
      } else {
        _isOnline = false;
        _checkAdminReminder();
      }
      notifyListeners();
    };

    _socketService.onServerPushEvent = (event, data) {
      final deviceUuid = LicenseService.instance.getOrCreateDeviceUuid();
      final fingerprint = LicenseService.instance.getHardwareFingerprint();
      final modems = _buildModemsPayload(gsmProvider);

      deviceUuid.then((uuid) {
        _socketService.notifyHardwareChange(
          deviceUuid: uuid,
          deviceFingerprint: fingerprint,
          modems: modems,
        );
      });
    };
  }

  Future<void> _checkAdminReminder() async {
    final shouldRemind = await LicenseService.instance.shouldShowAdminOnlineReminder();
    if (shouldRemind) {
      final days = await LicenseService.instance.getDaysSinceLastOnlineSync();
      _showAdminOnlineReminder = true;
      _adminNoticeMessage = 'تنبيه إداري: يرجى توصيل الإنترنت قريباً لإجراء فحص وتحديث دوري للنظام (آخر مزامنة منذ $days أيام).';
    } else {
      _showAdminOnlineReminder = false;
      _adminNoticeMessage = null;
    }
  }

  /// Manual sync / refresh trigger for UI buttons
  Future<void> syncWithServer(GsmProvider gsmProvider) async {
    _isChecking = true;
    _lastError = null;
    notifyListeners();

    // Verify locally first
    await _loadAndVerifyLocalLicenses(gsmProvider);

    final deviceUuid = await LicenseService.instance.getOrCreateDeviceUuid();
    final fingerprint = LicenseService.instance.getHardwareFingerprint();
    final modems = _buildModemsPayload(gsmProvider);
    _lastReportedModemsSignature = modems.map((m) => '${m['port']}_${m['iccid']}_${m['operator']}').join('|');

    if (_socketService.isConnected) {
      _socketService.notifyHardwareChange(
        deviceUuid: deviceUuid,
        deviceFingerprint: fingerprint,
        modems: modems,
      );
    } else {
      _socketService.connect(
        deviceUuid: deviceUuid,
        deviceFingerprint: fingerprint,
        modems: modems,
      );

      try {
        final List<Map<String, String>> strModems = modems
            .map((m) => m.map((k, v) => MapEntry(k, v.toString())))
            .toList();
        final data = await LicenseService.instance.sendHeartbeat(modems: strModems);
        if (data != null) {
          _handleServerState(data, gsmProvider);
        }
      } catch (_) {}
    }

    _isChecking = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _buildModemsPayload(GsmProvider gsmProvider) {
    final List<Map<String, dynamic>> list = [];
    for (var sim in gsmProvider.connectedSimList) {
      final cleanIccid = sim.iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
      if (cleanIccid.isNotEmpty && !cleanIccid.contains('Non') && !cleanIccid.contains('Lecture')) {
        list.add({
          'imei': '860123456789012',
          'port': sim.port,
          'iccid': cleanIccid,
          'operator': getOperatorCode(sim.operatorId),
        });
      }
    }
    return list;
  }

  void _onGsmHardwareChanged(GsmProvider gsmProvider) async {
    final modems = _buildModemsPayload(gsmProvider);
    final currentSignature = modems.map((m) => '${m['port']}_${m['iccid']}_${m['operator']}').join('|');

    // ONLY notify server if physical connected modems/SIMs have ACTUALLY changed!
    if (currentSignature == _lastReportedModemsSignature) {
      return;
    }

    _lastReportedModemsSignature = currentSignature;

    // Immediately verify newly inserted SIM locally
    await _loadAndVerifyLocalLicenses(gsmProvider);

    final deviceUuid = await LicenseService.instance.getOrCreateDeviceUuid();
    final fingerprint = LicenseService.instance.getHardwareFingerprint();

    if (_socketService.isConnected) {
      _socketService.notifyHardwareChange(
        deviceUuid: deviceUuid,
        deviceFingerprint: fingerprint,
        modems: modems,
      );
    }
  }

  /// Offline-First: Loads saved serials and verifies each SIM locally against ICCID & expiration
  Future<void> _loadAndVerifyLocalLicenses(GsmProvider gsmProvider) async {
    for (var sim in gsmProvider.connectedSimList) {
      final cleanIccid = sim.iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
      if (cleanIccid.isEmpty || cleanIccid.contains('Non') || cleanIccid.contains('Lecture')) continue;

      // Find saved serial (by ICCID, ICCID Hash, or operator ID)
      String? savedSerial = await LicenseService.instance.getLicenseForIccid(cleanIccid, sim.operatorId);
      
      if (savedSerial != null && savedSerial.isNotEmpty) {
        _simSerialByIccid[cleanIccid] = savedSerial;
        final payload = LicenseModel.parseSerialPayload(savedSerial);
        if (payload != null && payload['exp'] != null) {
          _simExpiryByIccid[cleanIccid] = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        }

        // Verify locally
        final opCode = getOperatorCode(sim.operatorId);
        final localStatus = LicenseService.instance.verifySerialLocally(
          serial: savedSerial,
          detectedIccid: cleanIccid,
          expectedOperatorCode: opCode,
        );

        switch (localStatus) {
          case SimLicenseStatus.active:
            _simActivationByIccid[cleanIccid] = true;
            _simStatusByIccid[cleanIccid] = 'مفعلة ومطابقة ⚡';
            break;
          case SimLicenseStatus.mismatch:
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'السيريال غير مطابق لهذه الشريحة ⚠️';
            break;
          case SimLicenseStatus.expired:
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'منتهية الصلاحية ⏱️';
            break;
          default:
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'غير مرخصة';
        }
      } else {
        _simActivationByIccid[cleanIccid] = false;
        _simStatusByIccid[cleanIccid] = 'شريحة غير مفعلة (أدخل السيريال)';
      }
    }

    _updateDefaultSimsAndLegacyMaps(gsmProvider);
    notifyListeners();
  }

  /// Process live state from Server (Confirms or updates license revocation/blocks)
  void _handleServerState(Map<String, dynamic> state, GsmProvider gsmProvider) {
    _isOnline = true;
    _showAdminOnlineReminder = false;
    _adminNoticeMessage = null;

    final serverSims = state['sims'] as Map<String, dynamic>?;

    if (serverSims != null) {
      for (var sim in gsmProvider.connectedSimList) {
        final cleanIccid = sim.iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
        if (cleanIccid.isEmpty || cleanIccid.contains('Non')) continue;

        final serial = _simSerialByIccid[cleanIccid];
        if (serial == null || serial.isEmpty) {
          _simActivationByIccid[cleanIccid] = false;
          _simStatusByIccid[cleanIccid] = 'شريحة غير مفعلة (أدخل السيريال)';
          continue;
        }

        Map<String, dynamic>? simData;
        if (serverSims.containsKey(cleanIccid)) {
          simData = serverSims[cleanIccid] as Map<String, dynamic>;
        } else if (serverSims.containsKey(sim.port)) {
          simData = serverSims[sim.port] as Map<String, dynamic>;
        }

        if (simData != null) {
          final simStatus = (simData['status'] ?? '').toString().toLowerCase();
          final licStatus = (simData['licenseStatus'] ?? '').toString().toLowerCase();

          if (simStatus == 'active' && licStatus == 'active') {
            final localStatus = LicenseService.instance.verifySerialLocally(
              serial: serial,
              detectedIccid: cleanIccid,
              expectedOperatorCode: getOperatorCode(sim.operatorId),
            );
            if (localStatus == SimLicenseStatus.active) {
              _simActivationByIccid[cleanIccid] = true;
              _simStatusByIccid[cleanIccid] = 'مفعلة ومطابقة ⚡ (Realtime)';
            } else {
              _simActivationByIccid[cleanIccid] = false;
              _simStatusByIccid[cleanIccid] = 'السيريال غير مطابق لهذه الشريحة ⚠️';
            }
          } else if (simStatus == 'mismatch_customer') {
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'مسجلة لزبون آخر ⚠️ (تضارب حسابات)';
          } else if (simStatus == 'suspended' || licStatus == 'suspended') {
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'معلقة من لوحة التحكم ⚠️';
          } else if (simStatus == 'blocked' || licStatus == 'revoked') {
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'محظورة / ملغاة من الإدارة 🚫';
          } else if (simStatus == 'expired' || licStatus == 'expired') {
            _simActivationByIccid[cleanIccid] = false;
            _simStatusByIccid[cleanIccid] = 'منتهية الصلاحية ⏱️';
          } else {
            // Keep locally verified status if valid, but mark as server unregistered
            final localStatus = LicenseService.instance.verifySerialLocally(
              serial: serial,
              detectedIccid: cleanIccid,
              expectedOperatorCode: getOperatorCode(sim.operatorId),
            );
            if (localStatus == SimLicenseStatus.active) {
              _simActivationByIccid[cleanIccid] = true;
              _simStatusByIccid[cleanIccid] = 'مفعلة ومطابقة ⚡';
            } else {
              _simActivationByIccid[cleanIccid] = false;
              _simStatusByIccid[cleanIccid] = 'شريحة غير مفعلة (أدخل السيريال)';
            }
          }
        }
      }
    }

    _updateDefaultSimsAndLegacyMaps(gsmProvider);
    notifyListeners();
  }

  void _updateDefaultSimsAndLegacyMaps(GsmProvider gsmProvider) {
    for (int opId in [1, 2, 3]) {
      final sims = gsmProvider.getSimsForOperator(opId);
      final activeSims = sims.where((s) => isIccidActivated(s.iccid)).toList();

      if (activeSims.isNotEmpty) {
        final currentDefault = sims.where((s) => s.isDefault).toList();
        if (currentDefault.isEmpty || !isIccidActivated(currentDefault.first.iccid)) {
          gsmProvider.setDefaultSim(activeSims.first.port);
        }
      } else {
        gsmProvider.clearDefaultSim(opId);
      }
    }

    for (int opId in [1, 2, 3]) {
      final defaultSim = gsmProvider.getDefaultSimForOperator(opId);
      if (defaultSim != null && defaultSim.iccid.isNotEmpty && !defaultSim.iccid.contains('Non')) {
        _isSimActivated[opId] = isIccidActivated(defaultSim.iccid);
        _simStatusLabels[opId] = getStatusLabelForIccid(defaultSim.iccid);
        _simSerialCodes[opId] = getSerialForIccid(defaultSim.iccid);
        _simExpiryDates[opId] = getExpiryForIccid(defaultSim.iccid);
      } else {
        _isSimActivated[opId] = false;
        _simStatusLabels[opId] = 'الشريحة غير متصلة 🔌';
        _simSerialCodes[opId] = '';
        _simExpiryDates[opId] = null;
      }
    }
  }

  /// Activate SIM card: Verifies and saves locally FIRST, then syncs with server
  Future<bool> activateSim({
    required int operatorId,
    required String serial,
    required String rawIccid,
    required String imei,
    GsmProvider? gsmProvider,
  }) async {
    final cleanSerial = serial.trim();
    if (cleanSerial.isEmpty) {
      _lastError = 'يرجى إدخال كود سيريال الترخيص (FX1....)';
      notifyListeners();
      return false;
    }

    final cleanIccid = rawIccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (cleanIccid.isEmpty || cleanIccid.contains('Non') || cleanIccid.contains('Lecture')) {
      _lastError = 'تعذر قراءة رقم ICCID من الشريحة. تأكد من توصيل المودم.';
      notifyListeners();
      return false;
    }

    _isChecking = true;
    _lastError = null;
    notifyListeners();

    // 1. Verify locally first (Offline validation)
    final localStatus = LicenseService.instance.verifySerialLocally(
      serial: cleanSerial,
      detectedIccid: cleanIccid,
      expectedOperatorCode: getOperatorCode(operatorId),
    );

    if (localStatus == SimLicenseStatus.mismatch) {
      _isChecking = false;
      _lastError = 'كود السيريال غير مطابق لهذه الشريحة (ICCID / المشغل غير مطابق).';
      notifyListeners();
      return false;
    } else if (localStatus == SimLicenseStatus.expired) {
      _isChecking = false;
      _lastError = 'كود السيريال منتهي الصلاحية ⏱️.';
      notifyListeners();
      return false;
    }

    // 2. Save locally immediately
    await LicenseService.instance.saveLicenseForIccid(cleanIccid, cleanSerial, operatorId);
    await LicenseService.instance.saveLicenseSerial(operatorId, cleanSerial);

    _simSerialByIccid[cleanIccid] = cleanSerial;
    _simActivationByIccid[cleanIccid] = true;
    _simStatusByIccid[cleanIccid] = 'مفعلة بنجاح ⚡';

    _simSerialCodes[operatorId] = cleanSerial;
    _isSimActivated[operatorId] = true;
    _simStatusLabels[operatorId] = 'مفعلة بنجاح ⚡';

    final payload = LicenseModel.parseSerialPayload(cleanSerial);
    if (payload != null && payload['exp'] != null) {
      final exp = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      _simExpiryByIccid[cleanIccid] = exp;
      _simExpiryDates[operatorId] = exp;
    }

    // 3. Attempt server registration in background
    try {
      final result = await LicenseService.instance.activateLicenseWithServer(
        serial: cleanSerial,
        imei: imei,
        rawIccid: cleanIccid,
      );
      if (result['expiresAt'] != null) {
        final exp = DateTime.tryParse(result['expiresAt']);
        _simExpiryByIccid[cleanIccid] = exp;
        _simExpiryDates[operatorId] = exp;
      }
    } catch (_) {
      // Offline mode: It still works locally!
    }

    final gsm = gsmProvider ?? _cachedGsmProvider;
    if (gsm != null) {
      _onGsmHardwareChanged(gsm);
    }

    _isChecking = false;
    notifyListeners();
    return true;
  }
}
