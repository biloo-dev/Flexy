import 'package:flutter/material.dart';
import '../services/gsm_service.dart';

class ModemTerminalView extends StatefulWidget {
  const ModemTerminalView({super.key});

  @override
  State<ModemTerminalView> createState() => _ModemTerminalViewState();
}

class _ModemTerminalViewState extends State<ModemTerminalView> {
  final _commandController = TextEditingController(text: 'AT');
  final _scrollController = ScrollController();
  String _selectedPort = '';
  int _baudRate = 9600;
  bool _isSending = false;
  bool _isScanningPorts = false;

  List<String> _portsList = [];
  final List<String> _logs = [
    '[SYSTEM] Console Terminal AT & Modems USB Initialisée.',
    '[SYSTEM] Connectez une clé / modem USB GSM pour démarrer la communication série.',
  ];

  @override
  void initState() {
    super.initState();
    _scanPorts();
  }

  void _scanPorts() async {
    setState(() => _isScanningPorts = true);
    final ports = await GsmService.instance.getAvailablePortsFromOs();
    if (mounted) {
      setState(() {
        _portsList = ports;
        if (ports.isNotEmpty) {
          if (!ports.contains(_selectedPort)) {
            _selectedPort = ports.first;
          }
        } else {
          _selectedPort = '';
        }
        _isScanningPorts = false;
      });
      _addLog(ports.isNotEmpty
          ? '[SYSTEM] Ports Série OS Détectés: ${_portsList.join(", ")}'
          : '[SYSTEM] Aucun périphérique série COM détecté sur le système.');
    }
  }

  void _addLog(String log) {
    setState(() {
      final timeStr = DateTime.now().toString().split(' ')[1].split('.')[0];
      _logs.add('[$timeStr] $log');
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendAtCommand([String? cmdOverride]) async {
    final cmd = (cmdOverride ?? _commandController.text).trim();
    if (cmd.isEmpty) return;

    if (_selectedPort.isEmpty) {
      _addLog('[ERREUR] Aucun port COM sélectionné. Veuillez connecter un modem USB.');
      return;
    }

    setState(() => _isSending = true);
    _addLog('TX -> $_selectedPort: $cmd');

    final response = await GsmService.instance.sendRawAtCommand(
      _selectedPort,
      cmd,
      baudRate: _baudRate,
    );

    if (mounted) {
      setState(() => _isSending = false);
      _addLog('RX <- $_selectedPort:\n$response');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _logs.add('[SYSTEM] Console effacée.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Terminal AT & Diagnostics USB GSM',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27282A)),
                  icon: _isScanningPorts
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                      : const Icon(Icons.refresh, color: Colors.greenAccent),
                  label: const Text('Détecter Ports OS'),
                  onPressed: _isScanningPorts ? null : _scanPorts,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Controls Bar (Port selector, Baud rate)
            Card(
              color: const Color(0xFF27282A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Port COM Modem',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: _portsList.contains(_selectedPort)
                            ? _selectedPort
                            : (_portsList.isNotEmpty ? _portsList.first : null),
                        items: _portsList.isEmpty
                            ? const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Aucun port COM détecté'),
                                )
                              ]
                            : _portsList.map((p) {
                                return DropdownMenuItem<String?>(value: p, child: Text(p));
                              }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPort = val);
                            _addLog('[SYSTEM] Port actif changé pour: $val');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Vitesse (Baud Rate)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: _baudRate,
                        items: const [
                          DropdownMenuItem(value: 9600, child: Text('9600 bps')),
                          DropdownMenuItem(value: 19200, child: Text('19200 bps')),
                          DropdownMenuItem(value: 115200, child: Text('115200 bps')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _baudRate = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPresetChip('AT'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+COPS?'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+CSQ'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+CSCS="GSM"'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+CUSD=1,"*222#"'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+CUSD=1,"*710#"'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+CUSD=1,"*222#",15'),
                            const SizedBox(width: 6),
                            _buildPresetChip('AT+CUSD=1,"*710#",15'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Command Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Saisir la commande AT',
                      hintText: 'ex: AT, AT+COPS?, AT+CUSD=1,"*710#",15',
                      prefixIcon: Icon(Icons.code, color: Colors.greenAccent),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (cmd) => _sendAtCommand(cmd),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.send_rounded),
                    label: const Text('ENVOYER (TX)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isSending ? null : () => _sendAtCommand(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Log Console Header & Clear
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Moniteur Série Live (Console Output)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                  label: const Text('Effacer Console', style: TextStyle(color: Colors.redAccent)),
                  onPressed: _clearLogs,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Monospace Serial Console Window
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101018),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: SelectionArea(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isTx = log.contains('TX ->');
                      final isSystem = log.contains('[SYSTEM]');
                      final isError = log.contains('[ERREUR]');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.4,
                            color: isTx
                                ? Colors.cyanAccent
                                : (isError
                                    ? Colors.redAccent
                                    : (isSystem ? Colors.yellowAccent : Colors.greenAccent[400])),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String cmd) {
    return ActionChip(
      label: Text(cmd, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF1E1E2C),
      onPressed: () {
        _commandController.text = cmd;
        _sendAtCommand(cmd);
      },
    );
  }
}
