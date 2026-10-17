import 'dart:convert';
import 'package:crypto/crypto.dart';

enum SimLicenseStatus {
  active,
  unlicensed,
  expired,
  mismatch,
  blocked,
}

class LicenseModel {
  final int operatorId; // 1: Djezzy, 2: Mobilis, 3: Ooredoo
  final String serial;
  final String? licenseId;
  final String? iccidHash;
  final String? deviceId;
  final String? operatorCode;
  final List<String> features;
  final DateTime? expiresAt;
  final SimLicenseStatus status;
  final String? reason;

  LicenseModel({
    required this.operatorId,
    required this.serial,
    this.licenseId,
    this.iccidHash,
    this.deviceId,
    this.operatorCode,
    this.features = const ['FLEXI'],
    this.expiresAt,
    this.status = SimLicenseStatus.unlicensed,
    this.reason,
  });

  bool get isActive => status == SimLicenseStatus.active;

  /// Parse the payload segment from an FX1.<base64url_payload>.<base64url_sig> serial
  static Map<String, dynamic>? parseSerialPayload(String serial) {
    if (!serial.startsWith('FX1.')) return null;
    final parts = serial.trim().split('.');
    if (parts.length != 3) return null;

    try {
      var payloadEncoded = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payloadEncoded.length % 4 != 0) {
        payloadEncoded += '=';
      }
      final decodedJson = utf8.decode(base64.decode(payloadEncoded));
      return jsonDecode(decodedJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Calculates SHA-256 hex hash of a raw ICCID
  static String hashIccid(String rawIccid) {
    final clean = rawIccid.replaceAll(RegExp(r'\s+|-'), '').toUpperCase();
    return sha256.convert(utf8.encode(clean)).toString();
  }
}
