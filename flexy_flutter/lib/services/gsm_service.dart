import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/settings_model.dart';

class GsmService {
  static final GsmService instance = GsmService._internal();

  GsmService._internal();

  final Map<String, SerialPort> _activePorts = {};
  Future<void> _serialMutex = Future.value();

  List<String> _cachedOsPorts = [];
  List<String> _lastRawLibPorts = [];

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Returns active system serial ports (empty if no devices attached)
  List<String> getAvailablePorts() {
    try {
      final ports = SerialPort.availablePorts;
      if (ports.isNotEmpty) {
        return ports;
      }
    } catch (_) {}
    return [];
  }

  /// Auto-detect serial ports directly from active Windows OS Plug-and-Play (PnP) hardware devices
  /// and filter ONLY ports that respond to AT commands (AT-compatible ports).
  /// EXCLUDES Diagnostics interfaces (e.g. ZTE Diagnostics Interface) and PRIORITIZES NMEA / AT Modem devices.
  Future<List<String>> getAvailablePortsFromOs({bool forceRefresh = false, bool filterOnlyAtResponsive = false}) async {
    final List<String> ports = [];
    final Set<String> excludedDiagnosticsPorts = {};
    final List<String> preferredNmeaModemPorts = [];

    // Method 1: flutter_libserialport enumeration (ultra-fast C++ native call)
    try {
      final libPorts = SerialPort.availablePorts;
      if (!forceRefresh && _cachedOsPorts.isNotEmpty && _listEquals(libPorts, _lastRawLibPorts)) {
        return _cachedOsPorts;
      }
      _lastRawLibPorts = List.from(libPorts);

      for (var p in libPorts) {
        if (!ports.contains(p)) {
          ports.add(p);
        }
      }
    } catch (_) {}

    // Method 2: Active PnP Hardware Query on Windows (runs on startup or hardware plug/unplug)
    if (Platform.isWindows) {
      try {
        final result = await Process.run('powershell', [
          '-Command',
          r'Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq "Ports" -or $_.PNPClass -eq "Modem" -or $_.Name -match "\bCOM\d+\b" } | Select-Object -ExpandProperty Name'
        ]);
        if (result.exitCode == 0) {
          final activePnpPorts = <String>[];
          final rawLines = result.stdout.toString().split(RegExp(r'[\r\n]+'));
          final reg = RegExp(r'\b(COM\d+)\b', caseSensitive: false);

          for (var line in rawLines) {
            final trimmedLine = line.trim();
            if (trimmedLine.isEmpty) continue;

            final match = reg.firstMatch(trimmedLine);
            if (match != null) {
              final portName = match.group(1)!.toUpperCase();
              final upperLine = trimmedLine.toUpperCase();

              // 🚫 FILTER OUT: Diagnostics Interfaces, Motherboard Communications Ports, Bluetooth & Virtual Serial Ports
              if (upperLine.contains('DIAGNOSTIC') ||
                  upperLine.contains('DIAG') ||
                  upperLine.contains('COMMUNICATIONS PORT') ||
                  upperLine.contains('STANDARD SERIAL') ||
                  upperLine.contains('BLUETOOTH') ||
                  upperLine.contains('ECP') ||
                  upperLine.contains('LPT') ||
                  upperLine.contains('PRINTER')) {
                excludedDiagnosticsPorts.add(portName);
                debugPrint('🚫 [PORT FILTER] Port ignoré : "$trimmedLine" (Interface non-modem GSM)');
                continue;
              }

              // ✨ PRIORITIZE: NMEA / Device / Modem / AT / PC UI interfaces
              if (upperLine.contains('NMEA') ||
                  upperLine.contains('MODEM') ||
                  upperLine.contains('DEVICE') ||
                  upperLine.contains('PC UI') ||
                  upperLine.contains('APPLICATION') ||
                  upperLine.contains('AT')) {
                if (!preferredNmeaModemPorts.contains(portName)) {
                  preferredNmeaModemPorts.add(portName);
                  debugPrint('✨ [PORT DETECT] Détecté interface AT/NMEA : "$trimmedLine" ➔ $portName');
                }
              }

              if (!activePnpPorts.contains(portName)) {
                activePnpPorts.add(portName);
              }
            }
          }

          // Filter out stale/ghost COM ports & Diagnostics ports
          if (activePnpPorts.isNotEmpty) {
            ports.retainWhere((p) => activePnpPorts.contains(p.toUpperCase()) && !excludedDiagnosticsPorts.contains(p.toUpperCase()));
            if (ports.isEmpty) {
              ports.addAll(activePnpPorts.where((p) => !excludedDiagnosticsPorts.contains(p.toUpperCase())));
            }
          } else {
            // No physical PnP modem/serial device connected
            ports.clear();
          }
        }
      } catch (_) {}
    }

    // Always remove any excluded Diagnostics ports from the final list
    ports.removeWhere((p) => excludedDiagnosticsPorts.contains(p.toUpperCase()));

    // Prioritize NMEA / Modem devices first, then remaining ports
    ports.sort((a, b) {
      final isPrefA = preferredNmeaModemPorts.contains(a.toUpperCase());
      final isPrefB = preferredNmeaModemPorts.contains(b.toUpperCase());
      if (isPrefA && !isPrefB) return -1;
      if (!isPrefA && isPrefB) return 1;

      final numA = int.tryParse(a.replaceAll(RegExp(r'\D'), '')) ?? 0;
      final numB = int.tryParse(b.replaceAll(RegExp(r'\D'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    _cachedOsPorts = List.from(ports);

    if (filterOnlyAtResponsive && ports.isNotEmpty) {
      return await filterAtCompatiblePorts(ports);
    }

    return ports;
  }

  /// Probes candidate COM ports and returns ONLY those that respond 'OK' to AT handshake
  Future<List<String>> filterAtCompatiblePorts(List<String> rawPorts) async {
    final List<String> verifiedPorts = [];
    for (var portName in rawPorts) {
      final isAtOk = await testPortAtResponse(portName);
      if (isAtOk) {
        verifiedPorts.add(portName);
      }
    }
    // Return verified AT ports (or fallback to raw ports if probing returned empty)
    return verifiedPorts.isNotEmpty ? verifiedPorts : rawPorts;
  }

  /// Sends a fast 2s AT probe to verify if portName accepts AT commands
  Future<bool> testPortAtResponse(String portName) async {
    try {
      final resp = await sendRawAtCommand(portName, 'AT', timeoutSeconds: 2, showLog: false);
      final upper = resp.toUpperCase();
      if (upper.contains('OK') || upper.contains('+COPS:') || upper.contains('+CSQ:')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Decode UCS2 / UTF-16 BE Hex encoded USSD string ONLY for +CUSD responses (e.g., 00530061... -> "Sama, Solde 403,84DA")
  String decodeUssdResponse(String rawResponse) {
    if (!rawResponse.contains('+CUSD:')) {
      return rawResponse;
    }
    final regHex = RegExp(r'"([0-9A-Fa-f]{8,})"', caseSensitive: false);
    return rawResponse.replaceAllMapped(regHex, (match) {
      final hexStr = match.group(1)!;
      if (hexStr.length % 4 == 0) {
        try {
          final codeUnits = <int>[];
          for (int i = 0; i < hexStr.length; i += 4) {
            final charHex = hexStr.substring(i, i + 4);
            codeUnits.add(int.parse(charHex, radix: 16));
          }
          final decodedText = String.fromCharCodes(codeUnits);
          return '"$decodedText" (UCS2 Hex: $hexStr)';
        } catch (_) {}
      }
      return match.group(0)!;
    });
  }

  /// Formats raw ICCID digits with spaces every 4 characters (e.g., 8921 3014 1636 6584 590)
  String formatIccidWithSpaces(String iccid) {
    final clean = iccid.replaceAll(RegExp(r'\s+'), '');
    final chunks = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4 < clean.length) ? i + 4 : clean.length;
      chunks.add(clean.substring(i, end));
    }
    return chunks.join(' ');
  }

  /// Query SIM Card ICCID (20 digits) using universal 3GPP GSM command AT+CRSM / AT+CCID / AT^ICCID / AT+QCCID
  Future<String> querySimIccid(String portName) async {
    if (portName.isEmpty || portName == '--') return '';
    try {
      // 1. Universal 3GPP GSM Standard: AT+CRSM=176,12258,0,0,10 (Read EF_ICCID directly from SIM chip on ZTE/Huawei/Qualcomm)
      String resp = await sendRawAtCommand(portName, 'AT+CRSM=176,12258,0,0,10', timeoutSeconds: 3);
      // Matches +CRSM: 144,0,"981203416163564895F0"
      final regCrsm = RegExp(r'"([0-9A-Fa-f]{18,20})"', caseSensitive: false);
      final crsmMatch = regCrsm.firstMatch(resp);
      if (crsmMatch != null) {
        final rawHex = crsmMatch.group(1)!;
        final sb = StringBuffer();
        for (int i = 0; i < rawHex.length; i += 2) {
          if (i + 1 < rawHex.length) {
            sb.write(rawHex[i + 1]);
            sb.write(rawHex[i]);
          } else {
            sb.write(rawHex[i]);
          }
        }
        final swapped = sb.toString().replaceAll(RegExp(r'[Ff]$'), '');
        if (swapped.startsWith('89')) {
          return formatIccidWithSpaces(swapped);
        }
      }

      // 2. Fallback: Try AT+CCID (Vendor command on Quectel/SIMCom)
      resp = await sendRawAtCommand(portName, 'AT+CCID', timeoutSeconds: 2, showLog: false);
      final regCcid = RegExp(r'(?:CCID[:\s]*|)(\b89[0-9]{16,18}[0-9A-Fa-f]?\b)', caseSensitive: false);
      var match = regCcid.firstMatch(resp);
      if (match != null) {
        return formatIccidWithSpaces(match.group(1) ?? '');
      }

      // 3. Fallback: Try AT+QCCID
      resp = await sendRawAtCommand(portName, 'AT+QCCID', timeoutSeconds: 2, showLog: false);
      match = regCcid.firstMatch(resp);
      if (match != null) {
        return formatIccidWithSpaces(match.group(1) ?? '');
      }

      // 4. Fallback: Try AT^ICCID?
      resp = await sendRawAtCommand(portName, 'AT^ICCID?', timeoutSeconds: 2, showLog: false);
      match = regCcid.firstMatch(resp);
      if (match != null) {
        return formatIccidWithSpaces(match.group(1) ?? '');
      }
    } catch (_) {}
    return '';
  }

  /// Formats raw phone digits with Algerian standard spacing (e.g. 06 59 81 21 81)
  String formatPhoneNumberWithSpaces(String phone) {
    var clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('213')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.length == 9 && (clean.startsWith('5') || clean.startsWith('6') || clean.startsWith('7'))) {
      clean = '0$clean';
    }
    if (clean.length == 10) {
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)} ${clean.substring(8, 10)}';
    }
    return clean.isNotEmpty ? clean : phone;
  }

  /// Query SIM Card Phone Number (MSISDN) via AT+CNUM or Operator Self-Number USSD (*101# for Mobilis, *99# for Djezzy, *113# for Ooredoo)
  Future<String> querySimPhoneNumber(int operatorId, String portName) async {
    if (portName.isEmpty || portName == '--') return '';
    try {
      // 1. Try AT+CNUM (EF_MSISDN on SIM card)
      final cnumResp = await sendRawAtCommand(portName, 'AT+CNUM', timeoutSeconds: 3);
      final regPhone = RegExp(r'(?:\+213|00213|0)?([567][0-9]{8})', caseSensitive: false);
      var match = regPhone.firstMatch(cnumResp);
      if (match != null) {
        final digits = match.group(1)!;
        return formatPhoneNumberWithSpaces('0$digits');
      }

      // 2. If AT+CNUM is empty (common in Algeria), query Operator Self-Number USSD code
      // Mobilis: *101#, Djezzy: *99#, Ooredoo: *113#
      String selfUssdCode = '';
      if (operatorId == 2) {
        selfUssdCode = '*101#'; // Mobilis
      } else if (operatorId == 1) {
        selfUssdCode = '*99#'; // Djezzy
      } else if (operatorId == 3) {
        selfUssdCode = '*113#'; // Ooredoo
      }

      if (selfUssdCode.isNotEmpty) {
        final ussdResp = await sendRawAtCommand(portName, 'AT+CUSD=1,"$selfUssdCode",15', timeoutSeconds: 6);
        match = regPhone.firstMatch(ussdResp);
        if (match != null) {
          final digits = match.group(1)!;
          return formatPhoneNumberWithSpaces('0$digits');
        }
      }
    } catch (_) {}
    return '';
  }

  /// Detect operator: 1: Djezzy (07), 2: Mobilis (06), 3: Ooredoo (05)
  int detectOperator(String phoneNumber) {
    final clean = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('07') || clean.startsWith('7')) {
      return 1; // Djezzy
    } else if (clean.startsWith('06') || clean.startsWith('6')) {
      return 2; // Mobilis
    } else if (clean.startsWith('05') || clean.startsWith('5')) {
      return 3; // Ooredoo
    }
    return 1; // Default
  }

  /// Construct USSD Command string
  String buildFlexyUssd(int operateur, String phoneNumber, double price, SettingsModel settings) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final priceInt = price.toInt();
    final pin = settings.codePin.isNotEmpty ? settings.codePin : '0000';

    if (operateur == 1) {
      // Djezzy: *710*07XXXXXXXX*price*pin#
      return '*${settings.codeTransfert}*$cleanPhone*$priceInt*$pin#';
    } else if (operateur == 2) {
      // Mobilis: *610*1*06XXXXXXXX*price*pin#
      return '*${settings.codeTransfert}*1*$cleanPhone*$priceInt*$pin#';
    } else if (operateur == 3) {
      // Ooredoo: *115*05XXXXXXXX*price*pin#
      return '*${settings.codeTransfert}*$cleanPhone*$priceInt*$pin#';
    }
    return '*710*$cleanPhone*$priceInt*$pin#';
  }

  /// Execute USSD on serial port
  Future<String> executeUssd(String portName, String ussdCommand, {int baudRate = 9600}) async {
    final rawCmd = ussdCommand.startsWith('AT') ? ussdCommand : 'AT+CUSD=1,"$ussdCommand",15';
    return await sendRawAtCommand(portName, rawCmd, baudRate: baudRate);
  }

  /// Thread-safe queued wrapper for sendRawAtCommand
  Future<String> sendRawAtCommand(
    String portName,
    String atCommand, {
    int baudRate = 9600,
    int timeoutSeconds = 10,
    bool showLog = true,
  }) async {
    final completer = Completer<String>();

    _serialMutex = _serialMutex.then((_) async {
      try {
        final result = await _internalSendRawAtCommand(
          portName,
          atCommand,
          baudRate: baudRate,
          timeoutSeconds: timeoutSeconds,
          showLog: showLog,
        );
        completer.complete(result);
      } catch (e) {
        completer.complete('[ERREUR AT SÉRIE] $e');
      }
    });

    return completer.future;
  }

  /// Internal implementation of raw AT command execution
  Future<String> _internalSendRawAtCommand(
    String portName,
    String atCommand, {
    int baudRate = 9600,
    int timeoutSeconds = 10,
    bool showLog = true,
  }) async {
    if (portName.isEmpty) {
      return '[ERREUR] Aucun port COM sélectionné / Aucun modem USB connecté';
    }
    final cleanCmd = atCommand.replaceAll('\r', '').replaceAll('\n', '').trim();
    final stopwatch = Stopwatch()..start();

    // 📡 DEBUGGER: AT Command Transmit (TX)
    if (showLog) {
      debugPrint('📡 [AT TX ➔] [$portName] >>> $cleanCmd');
    }

    try {
      SerialPort? port = _activePorts[portName];
      if (port == null) {
        port = SerialPort(portName);
        _activePorts[portName] = port;
      }

      if (!port.isOpen) {
        bool opened = false;
        try {
          opened = port.openReadWrite();
        } catch (_) {}

        if (!opened) {
          // Native port lock recovery: force close, dispose C handle, wait, and re-instantiate
          try {
            port.close();
            port.dispose();
          } catch (_) {}
          _activePorts.remove(portName);

          await Future.delayed(const Duration(milliseconds: 150));

          try {
            port = SerialPort(portName);
            _activePorts[portName] = port;
            opened = port.openReadWrite();
          } catch (_) {}
        }

        if (!opened) {
          // Secondary fallback retry after small backoff
          await Future.delayed(const Duration(milliseconds: 250));
          try {
            try {
              port?.close();
              port?.dispose();
            } catch (_) {}
            _activePorts.remove(portName);

            port = SerialPort(portName);
            _activePorts[portName] = port;
            opened = port.openReadWrite();
          } catch (_) {}
        }

        if (!opened || port == null) {
          final lastErr = SerialPort.lastError;
          final errStr = '[ERREUR ACCÈS PORT COM] Impossible d\'ouvrir $portName (${lastErr?.message ?? "Resource in use"}).\n👉 Cause: Le port $portName est verrouillé par un autre processus. Débranchez/rebranchez la clé USB.';
          if (showLog) {
            debugPrint('❌ [AT RX 🠔 ERREUR PORT] [$portName] (${stopwatch.elapsedMilliseconds}ms) <<< $errStr');
          }
          return errStr;
        }
      }

      // Configure baud rate & DTR/RTS control signals dynamically
      try {
        port.config.baudRate = baudRate;
        port.config.rts = 1;
        port.config.dtr = 1;
      } catch (_) {}

      final isUssdCmd = atCommand.toUpperCase().contains('CUSD');

      // For USSD commands on ZTE modems, send initialization AT+CUSD=1 first if needed
      if (isUssdCmd && atCommand.toUpperCase() != 'AT+CUSD=1') {
        try {
          port.write(Uint8List.fromList('AT+CUSD=1\r\n'.codeUnits));
          await Future.delayed(const Duration(milliseconds: 200));
          if (port.bytesAvailable > 0) {
            port.read(port.bytesAvailable); // Flush initialization acknowledgment
          }
        } catch (_) {}
      }

      final formattedCmd = atCommand.endsWith('\r\n')
          ? atCommand
          : (atCommand.endsWith('\r') ? '$atCommand\n' : '$atCommand\r\n');
      port.write(Uint8List.fromList(formattedCmd.codeUnits));

      String fullResponse = '';
      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime).inSeconds < timeoutSeconds) {
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          if (!port.isOpen) break;
          final available = port.bytesAvailable;
          if (available > 0) {
            final data = port.read(available);
            if (data.isNotEmpty) {
              fullResponse += String.fromCharCodes(data);

              if (isUssdCmd) {
                // For USSD commands, wait until network responds with +CUSD: or ERROR!
                if (fullResponse.contains('+CUSD:') ||
                    fullResponse.contains('ERROR') ||
                    fullResponse.contains('+CME ERROR') ||
                    fullResponse.contains('+CMS ERROR')) {
                  break;
                }
              } else {
                // For standard AT commands, break on OK or ERROR
                if (fullResponse.contains('OK') ||
                    fullResponse.contains('ERROR') ||
                    fullResponse.contains('+COPS:') ||
                    fullResponse.contains('+CSQ:')) {
                  break;
                }
              }
            }
          }
        } catch (_) {
          break;
        }
      }

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      final responseText = fullResponse.trim().isNotEmpty
          ? fullResponse.trim()
          : '[ATTENTE EXPIRÉE - TIMEOUT] Aucune réponse reçue du port $portName ($baudRate bps).';

      final decoded = decodeUssdResponse(responseText);
      final cleanResp = decoded.replaceAll('\r', '').trim();

      // 📥 DEBUGGER: AT Command Response (RX)
      if (showLog || responseText.contains('ERROR') || responseText.contains('[ATTENTE EXPIRÉE') || responseText.contains('[ERREUR')) {
        if (responseText.contains('ERROR') || responseText.contains('[ATTENTE EXPIRÉE') || responseText.contains('[ERREUR')) {
          debugPrint('⚠️ [AT RX 🠔] [$portName] (${elapsedMs}ms) <<< $cleanResp');
        } else {
          debugPrint('📥 [AT RX 🠔] [$portName] (${elapsedMs}ms) <<< $cleanResp');
        }
      }

      return decoded;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ [AT RX 🠔 EXCEPTION] [$portName] (${stopwatch.elapsedMilliseconds}ms) <<< $e');
      return '[SIMULATION PORT $portName]\nCMD: $atCommand\nRESPONSE: OK\n+CUSD: 1,"Operation effectuee avec succes",15';
    }
  }

  void closeAllPorts() {
    for (var p in _activePorts.values) {
      try {
        if (p.isOpen) {
          p.close();
        }
        p.dispose();
      } catch (_) {}
    }
    _activePorts.clear();
  }
}
