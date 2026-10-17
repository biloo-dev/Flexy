import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/authorization/app_permissions.dart';
import '../core/authorization/permission_guard.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../services/gsm_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.greenAccent,
              tabs: const [
                Tab(icon: Icon(Icons.sim_card), text: 'Djezzy Settings'),
                Tab(icon: Icon(Icons.sim_card), text: 'Mobilis Settings'),
                Tab(icon: Icon(Icons.sim_card), text: 'Ooredoo Settings'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OperatorSettingsForm(
                    settings: settingsProvider.djezzySettings,
                    name: 'Djezzy',
                    defaultTransferCode: 710,
                    defaultBalanceCode: 710,
                  ),
                  _OperatorSettingsForm(
                    settings: settingsProvider.mobilisSettings,
                    name: 'Mobilis',
                    defaultTransferCode: 610,
                    defaultBalanceCode: 222,
                  ),
                  _OperatorSettingsForm(
                    settings: settingsProvider.ooredooSettings,
                    name: 'Ooredoo',
                    defaultTransferCode: 115,
                    defaultBalanceCode: 200,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorSettingsForm extends StatefulWidget {
  final SettingsModel settings;
  final String name;
  final int defaultTransferCode;
  final int defaultBalanceCode;

  const _OperatorSettingsForm({
    required this.settings,
    required this.name,
    required this.defaultTransferCode,
    required this.defaultBalanceCode,
  });

  @override
  State<_OperatorSettingsForm> createState() => _OperatorSettingsFormState();
}

class _OperatorSettingsFormState extends State<_OperatorSettingsForm> {
  late TextEditingController _transferCodeController;
  late TextEditingController _balanceCodeController;
  late TextEditingController _pinController;
  late String _selectedComPort;
  late bool _autoConfirmation;
  late bool _audioEnabled;

  @override
  void initState() {
    super.initState();
    _transferCodeController = TextEditingController(text: widget.settings.codeTransfert.toString());
    _balanceCodeController = TextEditingController(text: widget.settings.codeSolde.toString());
    _pinController = TextEditingController(text: widget.settings.codePin);
    _selectedComPort = widget.settings.comPort;
    _autoConfirmation = widget.settings.autoConfirmation;
    _audioEnabled = widget.settings.audioEnabled;
  }

  void _save() async {
    final updated = SettingsModel(
      id: widget.settings.id,
      typeOperator: widget.settings.typeOperator,
      codeTransfert: int.tryParse(_transferCodeController.text) ?? widget.defaultTransferCode,
      codeSolde: int.tryParse(_balanceCodeController.text) ?? widget.defaultBalanceCode,
      codePin: _pinController.text,
      comPort: _selectedComPort,
      autoConfirmation: _autoConfirmation,
      audioEnabled: _audioEnabled,
    );

    await Provider.of<SettingsProvider>(context, listen: false).updateSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Paramètres ${widget.name} sauvegardés!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePorts = GsmService.instance.getAvailablePorts();
    final String? initialPort = availablePorts.contains(_selectedComPort)
        ? _selectedComPort
        : (availablePorts.isNotEmpty ? availablePorts.first : null);

    return SingleChildScrollView(
      child: Card(
        color: const Color(0xFF27282A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration du Modem ${widget.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 32),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Port COM (Modem USB)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.usb, color: Colors.greenAccent),
                      ),
                      initialValue: initialPort,
                      items: availablePorts.isEmpty
                          ? const [DropdownMenuItem<String?>(value: null, child: Text('Aucun port COM / modem détecté'))]
                          : availablePorts.map((p) {
                              return DropdownMenuItem<String?>(value: p, child: Text(p));
                            }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedComPort = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: 'Code PIN SIM (ex: 0000)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.greenAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _transferCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code Transfert USSD',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.send_outlined, color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _balanceCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code Consultation Solde',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_outlined, color: Colors.greenAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text('Auto-Confirmation du Transfert'),
                subtitle: const Text('Confirmer automatiquement le dialogue USSD sans demande d\'intervention'),
                value: _autoConfirmation,
                onChanged: (val) => setState(() => _autoConfirmation = val),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Annonces Vocales (TTS Audio)'),
                subtitle: const Text('Activer la synthèse vocale pour confirmer vocalement les transferts'),
                value: _audioEnabled,
                onChanged: (val) => setState(() => _audioEnabled = val),
              ),

              const SizedBox(height: 28),
              PermissionGuard(
                permission: AppPermissions.settingsUpdate,
                fallback: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Colors.amberAccent),
                      SizedBox(width: 8),
                      Text('Modification des paramètres réservée aux administrateurs', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                    ],
                  ),
                ),
                child: SizedBox(
                  width: 220,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
