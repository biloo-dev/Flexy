import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/license_model.dart';

class LicenseService {
  static final LicenseService instance = LicenseService._internal();

  LicenseService._internal();

  String _baseUrl = 'https://flexy-api-efsc.onrender.com/api/v1';

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Get or create a persistent UUID for this machine
  Future<String> getOrCreateDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('flexi_device_uuid');
    if (uuid == null || uuid.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rand = sha256.convert(utf8.encode('$now-${Platform.localHostname}-${Platform.operatingSystem}')).toString();
      uuid = 'dev-${rand.substring(0, 12)}';
      await prefs.setString('flexi_device_uuid', uuid);
    }
    return uuid;
  }

  /// Compute hardware fingerprint (OS version, Hostname, Platform)
  String getHardwareFingerprint() {
    final raw = '${Platform.operatingSystem}-${Platform.operatingSystemVersion}-${Platform.localHostname}-${Platform.numberOfProcessors}';
    return 'FP-${sha256.convert(utf8.encode(raw)).toString().substring(0, 16).toUpperCase()}';
  }

  /// Save activated serial for a specific SIM ICCID / hash
  Future<void> saveLicenseForIccid(String rawIccid, String serial, [int? operatorId]) async {
    final cleanIccid = rawIccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (cleanIccid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Save under clean ICCID
    await prefs.setString('flexi_sim_license_iccid_$cleanIccid', serial.trim());

    // Save under ICCID without trailing 'F' if present
    if (cleanIccid.endsWith('F') || cleanIccid.endsWith('f')) {
      final noF = cleanIccid.substring(0, cleanIccid.length - 1);
      await prefs.setString('flexi_sim_license_iccid_$noF', serial.trim());
    } else {
      await prefs.setString('flexi_sim_license_iccid_${cleanIccid}F', serial.trim());
    }

    // Also index by SHA256 ICCID Hash
    final hash = LicenseModel.hashIccid(cleanIccid);
    await prefs.setString('flexi_sim_license_hash_$hash', serial.trim());

    // Also save under operator ID fallback if provided
    if (operatorId != null) {
      await prefs.setString('flexi_sim_license_serial_$operatorId', serial.trim());
    }
  }

  /// Get saved serial for a specific SIM ICCID with multiple fallbacks
  Future<String?> getLicenseForIccid(String rawIccid, [int? operatorId]) async {
    final cleanIccid = rawIccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (cleanIccid.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Direct ICCID lookup
    String? serial = prefs.getString('flexi_sim_license_iccid_$cleanIccid');
    if (serial != null && serial.isNotEmpty) return serial;

    // 2. ICCID without/with trailing 'F' lookup
    if (cleanIccid.endsWith('F') || cleanIccid.endsWith('f')) {
      final noF = cleanIccid.substring(0, cleanIccid.length - 1);
      serial = prefs.getString('flexi_sim_license_iccid_$noF');
      if (serial != null && serial.isNotEmpty) return serial;
    } else {
      serial = prefs.getString('flexi_sim_license_iccid_${cleanIccid}F');
      if (serial != null && serial.isNotEmpty) return serial;
    }

    // 3. SHA256 Hash lookup
    final hash = LicenseModel.hashIccid(cleanIccid);
    serial = prefs.getString('flexi_sim_license_hash_$hash');
    if (serial != null && serial.isNotEmpty) return serial;

    // 4. Operator ID legacy fallback
    if (operatorId != null) {
      serial = prefs.getString('flexi_sim_license_serial_$operatorId');
      if (serial != null && serial.isNotEmpty) return serial;
    }

    return null;
  }

  /// Remove saved license for a specific ICCID
  Future<void> removeLicenseForIccid(String rawIccid) async {
    final cleanIccid = rawIccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (cleanIccid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flexi_sim_license_iccid_$cleanIccid');
    final hash = LicenseModel.hashIccid(cleanIccid);
    await prefs.remove('flexi_sim_license_hash_$hash');
  }

  /// Save activated serial for a given operator (Legacy helper)
  Future<void> saveLicenseSerial(int operatorId, String serial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flexi_sim_license_serial_$operatorId', serial.trim());
  }

  /// Get saved serial for a given operator (Legacy helper)
  Future<String?> getSavedLicenseSerial(int operatorId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('flexi_sim_license_serial_$operatorId');
  }

  /// Save signed offline token and record sync timestamp
  Future<void> saveOfflineToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flexi_signed_state_token', token);
    await prefs.setInt('flexi_state_token_saved_at', DateTime.now().millisecondsSinceEpoch);
    await recordSuccessfulOnlineSync();
  }

  /// Record timestamp of successful online sync with server
  Future<void> recordSuccessfulOnlineSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flexi_last_online_sync', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get days passed since last online sync with server
  Future<int> getDaysSinceLastOnlineSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('flexi_last_online_sync') ?? prefs.getInt('flexi_state_token_saved_at');
    if (lastSync == null) return 0;
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastSync));
    return diff.inDays;
  }

  /// Check whether an administrative reminder notice should be displayed (e.g. after 7 days offline)
  Future<bool> shouldShowAdminOnlineReminder() async {
    final days = await getDaysSinceLastOnlineSync();
    return days >= 7;
  }

  /// Verify serial locally against detected ICCID (Offline First)
  SimLicenseStatus verifySerialLocally({
    required String serial,
    required String detectedIccid,
    required String expectedOperatorCode,
  }) {
    final cleanSerial = serial.trim();
    if (cleanSerial.isEmpty) {
      return SimLicenseStatus.unlicensed;
    }

    final payload = LicenseModel.parseSerialPayload(cleanSerial);
    if (payload == null) {
      return SimLicenseStatus.unlicensed;
    }

    // 1. Expiration check
    final expSeconds = payload['exp'] as int?;
    if (expSeconds != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
      if (expiry.isBefore(DateTime.now())) {
        return SimLicenseStatus.expired;
      }
    }

    // 2. Operator check (supports wildcard '*')
    final op = (payload['operator'] as String?)?.toUpperCase();
    if (op != null && op != '*' && op != expectedOperatorCode.toUpperCase()) {
      return SimLicenseStatus.mismatch;
    }

    // 3. ICCID hash check (supports wildcard '*' and handles trailing 'F' in GSM modems)
    final storedHash = (payload['iccidHash'] as String?)?.toLowerCase();
    if (storedHash != null && storedHash != '*' && detectedIccid.isNotEmpty) {
      final clean = detectedIccid.replaceAll(RegExp(r'\s+|-'), '').toUpperCase();
      
      final hash1 = LicenseModel.hashIccid(clean).toLowerCase();
      String hash2 = hash1;
      if (clean.endsWith('F')) {
        hash2 = LicenseModel.hashIccid(clean.substring(0, clean.length - 1)).toLowerCase();
      } else {
        hash2 = LicenseModel.hashIccid('${clean}F').toLowerCase();
      }

      if (hash1 != storedHash && hash2 != storedHash) {
        return SimLicenseStatus.mismatch;
      }
    }

    return SimLicenseStatus.active;
  }

  /// Safely decodes a JSON string without throwing unhandled FormatExceptions
  Map<String, dynamic>? _safeJsonDecode(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Send activation request to NestJS License Server
  Future<Map<String, dynamic>> activateLicenseWithServer({
    required String serial,
    required String imei,
    required String rawIccid,
    String appVersion = '1.0.0',
  }) async {
    final deviceUuid = await getOrCreateDeviceUuid();
    final cleanIccid = rawIccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    final cleanImei = imei.replaceAll(RegExp(r'\s+|-'), '').trim();

    final urlsToTry = [
      '$_baseUrl/licenses/activate',
      if (_baseUrl.contains('localhost'))
        '${_baseUrl.replaceFirst('localhost', '127.0.0.1')}/licenses/activate',
      if (_baseUrl.contains('127.0.0.1'))
        '${_baseUrl.replaceFirst('127.0.0.1', 'localhost')}/licenses/activate',
    ];

    String lastErrorMsg = 'فشل تفعيل الشريحة من السيرفر.';

    for (final urlStr in urlsToTry.toSet()) {
      try {
        final url = Uri.parse(urlStr);
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'licenseSerial': serial.trim(),
                'deviceId': deviceUuid,
                'imei': cleanImei.isNotEmpty ? cleanImei : '860123456789012',
                'iccid': cleanIccid,
                'appVersion': appVersion,
              }),
            )
            .timeout(const Duration(seconds: 8));

        final body = _safeJsonDecode(response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (body != null && body['success'] == true) {
            await recordSuccessfulOnlineSync();
            return body['data'] as Map<String, dynamic>;
          }
        }

        final errorObj = body?['error'] as Map<String, dynamic>?;
        lastErrorMsg = errorObj?['message'] ?? 'استجابة غير صالحة من السيرفر (HTTP ${response.statusCode})';
      } catch (e) {
        debugPrint('❌ [LICENSE ACTIVATION ERROR] Could not reach $urlStr: $e');
        lastErrorMsg = 'تعذر الاتصال بسيرفر التراخيص ($urlStr).';
      }
    }

    throw Exception(lastErrorMsg);
  }

  /// Send Heartbeat to NestJS License Server
  Future<Map<String, dynamic>?> sendHeartbeat({
    required List<Map<String, String>> modems,
    String appVersion = '1.0.0',
  }) async {
    final deviceUuid = await getOrCreateDeviceUuid();
    final fingerprint = getHardwareFingerprint();

    final urlsToTry = [
      '$_baseUrl/devices/heartbeat',
      if (_baseUrl.contains('localhost'))
        '${_baseUrl.replaceFirst('localhost', '127.0.0.1')}/devices/heartbeat',
      if (_baseUrl.contains('127.0.0.1'))
        '${_baseUrl.replaceFirst('127.0.0.1', 'localhost')}/devices/heartbeat',
    ];

    for (final urlStr in urlsToTry.toSet()) {
      try {
        final url = Uri.parse(urlStr);
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'deviceUuid': deviceUuid,
                'deviceFingerprint': fingerprint,
                'appVersion': appVersion,
                'modems': modems,
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = _safeJsonDecode(response.body);
          if (body != null && body['success'] == true) {
            await recordSuccessfulOnlineSync();
            final data = body['data'] as Map<String, dynamic>;
            final token = data['signedStateToken'] as String?;
            if (token != null && token.isNotEmpty) {
              await saveOfflineToken(token);
            }
            return data;
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
