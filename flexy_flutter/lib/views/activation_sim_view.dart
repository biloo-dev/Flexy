import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/gsm_provider.dart';
import '../providers/license_provider.dart';

class ActivationSimView extends StatefulWidget {
  const ActivationSimView({super.key});

  @override
  State<ActivationSimView> createState() => _ActivationSimViewState();
}

class _ActivationSimViewState extends State<ActivationSimView> {
  // Map of text controllers per SIM Port or ICCID
  final Map<String, TextEditingController> _codeControllers = {};

  // Loading state per SIM Port
  final Map<String, bool> _loadingByPort = {};

  // Expanded Accordion Index per operator
  final Map<int, int> _expandedIndexByOperator = {
    1: 0, // Djezzy
    2: 0, // Mobilis
    3: 0, // Ooredoo
  };

  TextEditingController _getControllerForSim(GsmConnectedSim sim, LicenseProvider licenseProvider) {
    final key = sim.port;
    if (!_codeControllers.containsKey(key)) {
      var initialText = licenseProvider.getSerialForIccid(sim.iccid);
      if (initialText.isEmpty) {
        initialText = licenseProvider.simSerialCodes[sim.operatorId] ?? '';
      }
      _codeControllers[key] = TextEditingController(text: initialText);
    }
    return _codeControllers[key]!;
  }

  @override
  void dispose() {
    for (var controller in _codeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleActivate({
    required int operatorId,
    required String operatorName,
    required String iccid,
    required String phone,
    required String port,
    required String code,
  }) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال كود سيريال الترخيص (FX1....).'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final cleanIccid = iccid.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (cleanIccid.isEmpty || cleanIccid.contains('Non') || cleanIccid.contains('Lecture')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر قراءة رقم ICCID من الشريحة. تأكد من إدخال الشريحة في المودم.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _loadingByPort[port] = true;
    });

    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
    final gsmProvider = Provider.of<GsmProvider>(context, listen: false);

    final success = await licenseProvider.activateSim(
      operatorId: operatorId,
      serial: cleanCode,
      rawIccid: cleanIccid,
      imei: '860123456789012',
      gsmProvider: gsmProvider,
    );

    if (!mounted) return;
    setState(() {
      _loadingByPort[port] = false;
    });

    if (success) {
      gsmProvider.setDefaultSim(port);
      final expiry = licenseProvider.getExpiryForIccid(cleanIccid);
      final expiryStr = expiry != null ? expiry.toString().split(' ')[0] : '1 an';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تم تفعيل شريحة $operatorName ($phone - Port $port) بنجاح! الصلاحية: $expiryStr',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final errorMsg = licenseProvider.lastError ?? 'فشل التفعيل. تأكد من صحة السيريال ومطابقة الشريحة.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String fieldLabel) {
    final clean = text.trim();
    if (clean.isEmpty || clean.contains('Non') || clean.contains('Lecture')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد بيانات صالحة للنسخ في حقل $fieldLabel.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final displaySample = clean.length > 25
        ? '${clean.substring(0, 12)}...${clean.substring(clean.length - 6)}'
        : clean;
    Clipboard.setData(ClipboardData(text: clean));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نسخ $fieldLabel بنجاح ($displaySample)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gsmProvider = Provider.of<GsmProvider>(context);
    final isAnyModemConnected = gsmProvider.connectedSimList.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1D),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Bar
            _buildTopHeader(isAnyModemConnected, gsmProvider.connectedSimList.length),

            const SizedBox(height: 20),

            // 2. Info Banner with Cyber Illustration
            _buildInfoBanner(),

            const SizedBox(height: 24),

            // 3. Middle Section: 3 SIM Operator Columns (Djezzy, Mobilis, Ooredoo)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      _buildOperatorColumn(1),
                      const SizedBox(height: 18),
                      _buildOperatorColumn(2),
                      const SizedBox(height: 18),
                      _buildOperatorColumn(3),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildOperatorColumn(1)),
                    const SizedBox(width: 18),
                    Expanded(child: _buildOperatorColumn(2)),
                    const SizedBox(width: 18),
                    Expanded(child: _buildOperatorColumn(3)),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // 4. Bottom Section: Pipeline
            _buildProcessPipelineCard(),
          ],
        ),
      ),
    );
  }

  // --- Top Header Widget ---
  Widget _buildTopHeader(bool isModemConnected, int totalConnectedCount) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: const Icon(
            Icons.menu_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ),

        const SizedBox(width: 14),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activation des puces SIM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Activez et gérez vos cartes SIM (Djezzy, Mobilis, Ooredoo) • Support Multi-SIM',
              style: TextStyle(
                color: Color(0xFF8F9BB3),
                fontSize: 12,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Connected Modem Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF091322),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isModemConnected ? const Color(0xFF00E6A8).withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isModemConnected ? const Color(0xFF00E6A8) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isModemConnected ? const Color(0xFF00E6A8) : const Color(0xFFEF4444),
                  boxShadow: [
                    BoxShadow(
                      color: isModemConnected ? const Color(0xFF00E6A8) : const Color(0xFFEF4444),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isModemConnected ? '$totalConnectedCount Modem(s) Connecté(s)' : 'Aucun Modem',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.signal_cellular_alt_rounded,
                color: isModemConnected ? const Color(0xFF00E6A8) : const Color(0xFFEF4444),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Real-Time Sync Info Banner ---
  Widget _buildInfoBanner() {
    return Consumer<LicenseProvider>(
      builder: (context, licenseProvider, _) {
        final isOnline = licenseProvider.isOnline;
        final remainingHours = licenseProvider.offlineHoursRemaining;
        final remainingDays = (remainingHours / 24).ceil();

        final bannerColor = isOnline ? const Color(0xFF00E6A8) : const Color(0xFFF59E0B);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF091424),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: bannerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOnline
                              ? 'مزامنة لحظية نشطة مع السيرفر (Real-Time Live Sync)'
                              : 'وضع العمل بدون إنترنت (Offline Mode - متبقي $remainingDays يوم)',
                          style: TextStyle(
                            color: bannerColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline
                          ? 'يتم التحقق اللحظي التلقائي لكل شريحة متصلة من السيرفر. عند تعليق أو حظر الشريحة تنعكس الحالة فوراً.'
                          : 'يمكنك العمل بدون إنترنت لمدة 72 ساعة، بعد انقضاء المدة يلزم الاتصال بالإنترنت لتأكيد حالة التراخيص.',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bannerColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bannerColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'ON-LINE ⚡' : 'OFF-LINE (ACTIF)',
                      style: TextStyle(
                        color: bannerColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Quick Sync / Retry Button
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
                tooltip: 'إعادة فحص الاتصال بالسيرفر الآن 🔄',
                onPressed: () {
                  final gsm = Provider.of<GsmProvider>(context, listen: false);
                  licenseProvider.syncWithServer(gsm);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Operator Column Dispatcher (Handles 0 SIMs, 1 SIM, or Multi-SIM Accordion) ---
  Widget _buildOperatorColumn(int operatorId) {
    return Consumer2<GsmProvider, LicenseProvider>(
      builder: (context, gsmProvider, licenseProvider, _) {
        final sims = gsmProvider.getSimsForOperator(operatorId);
        final opName = (operatorId == 1) ? 'DJEZZY' : ((operatorId == 2) ? 'MOBILIS' : 'OOREDOO');
        final brandColor = (operatorId == 1)
            ? const Color(0xFFF59E0B)
            : (operatorId == 2 ? const Color(0xFF10B981) : const Color(0xFFEF4444));

        if (sims.isEmpty) {
          // No SIM connected
          return _buildDisconnectedCard(operatorId, opName, brandColor);
        } else if (sims.length == 1) {
          // Single SIM
          return _buildSingleSimCard(operatorId, sims.first, brandColor, gsmProvider, licenseProvider);
        } else {
          // Multi-SIM Accordion
          return _buildMultiSimAccordionCard(operatorId, sims, brandColor, gsmProvider, licenseProvider);
        }
      },
    );
  }

  // --- 1. Disconnected Operator Card ---
  Widget _buildDisconnectedCard(int operatorId, String operatorName, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildOperatorLogo(operatorId),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operatorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Réseau $operatorName',
                    style: const TextStyle(color: Color(0xFF8F9BB3), fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.signal_cellular_off_rounded, color: Color(0xFF475569), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF334155).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF475569).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.usb_off_rounded, color: Color(0xFF94A3B8), size: 16),
                SizedBox(width: 8),
                Text(
                  'حالة الشريحة: غير متصلة 🔌',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF070D18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: [
                const Icon(Icons.sim_card_outlined, color: Color(0xFF64748B), size: 32),
                const SizedBox(height: 8),
                Text(
                  'لا توجد شريحة $operatorName متصلة حالياً',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'يرجى توصيل مفتاح USB أو المودم الذي يحتوي على الشريحة لقراءة بياناتها والتأكد من التفعيل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Single SIM Card View ---
  Widget _buildSingleSimCard(
    int operatorId,
    GsmConnectedSim sim,
    Color brandColor,
    GsmProvider gsmProvider,
    LicenseProvider licenseProvider,
  ) {
    final isSimActive = licenseProvider.isIccidActivated(sim.iccid);
    final statusLabel = licenseProvider.getStatusLabelForIccid(sim.iccid);
    final expiry = licenseProvider.getExpiryForIccid(sim.iccid);
    final expiryStr = expiry != null ? expiry.toString().split(' ')[0] : null;
    final savedSerial = licenseProvider.getSerialForIccid(sim.iccid);

    final codeController = _getControllerForSim(sim, licenseProvider);
    if (isSimActive && savedSerial.isNotEmpty && codeController.text != savedSerial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && codeController.text != savedSerial) {
          codeController.text = savedSerial;
        }
      });
    }

    final isLoading = _loadingByPort[sim.port] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSimActive ? brandColor : const Color(0xFF1E293B),
          width: isSimActive ? 1.6 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildOperatorLogo(operatorId),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sim.operatorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Port ${sim.port} • ${sim.balance}',
                    style: const TextStyle(color: Color(0xFF8F9BB3), fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              _SignalMiniBars(color: brandColor, bars: sim.signalLevel),
            ],
          ),

          const SizedBox(height: 14),

          _buildStatusCapsule(isSimActive, statusLabel, expiryStr),

          const SizedBox(height: 14),

          _buildFieldLabel('Numéro ICCID (20 chiffres SIM - Lecture Auto)'),
          const SizedBox(height: 7),
          _buildReadOnlyBox(
            value: sim.iccid,
            fieldLabel: 'رقم ICCID',
            brandColor: brandColor,
            suffixIcon: Icons.qr_code_scanner_rounded,
          ),

          const SizedBox(height: 16),

          _buildFieldLabel('Numéro de Téléphone à Activer (Lecture Auto)'),
          const SizedBox(height: 7),
          _buildReadOnlyBox(
            value: sim.phoneNumber,
            fieldLabel: 'رقم الهاتف',
            brandColor: brandColor,
            suffixIcon: Icons.phone_android_rounded,
          ),

          const SizedBox(height: 16),

          _buildSerialBoxHeader(codeController.text, isSimActive),
          const SizedBox(height: 7),
          _buildEditableCodeBox(
            controller: codeController,
            hintText: 'Entrez le code d\'activation (ex: FX1.eyJ...)',
            brandColor: brandColor,
            isReadOnly: isSimActive,
          ),

          const SizedBox(height: 24),

          _buildActivationButton(
            isSimActive: isSimActive,
            isLoading: isLoading,
            brandColor: brandColor,
            onActivate: () => _handleActivate(
              operatorId: operatorId,
              operatorName: sim.operatorName,
              iccid: sim.iccid,
              phone: sim.phoneNumber,
              port: sim.port,
              code: codeController.text,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Multi-SIM Accordion Card (قائمة الأكورديون للشرائح المتعددة لنفس المزود) ---
  Widget _buildMultiSimAccordionCard(
    int operatorId,
    List<GsmConnectedSim> sims,
    Color brandColor,
    GsmProvider gsmProvider,
    LicenseProvider licenseProvider,
  ) {
    final activeCount = sims.where((s) => licenseProvider.isIccidActivated(s.iccid)).length;
    final currentExpandedIndex = _expandedIndexByOperator[operatorId] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: brandColor.withValues(alpha: 0.6),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo + Multi-SIM Counter + Active Badges
          Row(
            children: [
              _buildOperatorLogo(operatorId),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sims.first.operatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: brandColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${sims.length} شرائح متصلة',
                          style: TextStyle(
                            color: brandColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Multi-SIM • $activeCount مفعلة من أصل ${sims.length}',
                    style: const TextStyle(color: Color(0xFF8F9BB3), fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.sim_card_download_rounded, color: brandColor, size: 22),
            ],
          ),

          const SizedBox(height: 16),

          // Render Accordion Tile for EACH connected SIM
          for (int i = 0; i < sims.length; i++) ...[
            _buildAccordionSimTile(
              index: i,
              sim: sims[i],
              operatorId: operatorId,
              brandColor: brandColor,
              isExpanded: currentExpandedIndex == i,
              onToggleExpand: () {
                setState(() {
                  _expandedIndexByOperator[operatorId] = (currentExpandedIndex == i) ? -1 : i;
                });
              },
              gsmProvider: gsmProvider,
              licenseProvider: licenseProvider,
            ),
            if (i < sims.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // Accordion Individual Tile
  Widget _buildAccordionSimTile({
    required int index,
    required GsmConnectedSim sim,
    required int operatorId,
    required Color brandColor,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    required GsmProvider gsmProvider,
    required LicenseProvider licenseProvider,
  }) {
    final isSimActive = licenseProvider.isIccidActivated(sim.iccid);
    final statusLabel = licenseProvider.getStatusLabelForIccid(sim.iccid);
    final expiry = licenseProvider.getExpiryForIccid(sim.iccid);
    final expiryStr = expiry != null ? expiry.toString().split(' ')[0] : null;
    final savedSerial = licenseProvider.getSerialForIccid(sim.iccid);

    final codeController = _getControllerForSim(sim, licenseProvider);
    if (isSimActive && savedSerial.isNotEmpty && codeController.text != savedSerial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && codeController.text != savedSerial) {
          codeController.text = savedSerial;
        }
      });
    }

    final isLoading = _loadingByPort[sim.port] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFF070E1C) : const Color(0xFF091122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? brandColor.withValues(alpha: 0.5)
              : (sim.isDefault ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFF1E293B)),
          width: isExpanded || sim.isDefault ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Accordion Header Bar
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    sim.isDefault ? Icons.star_rounded : Icons.sim_card_rounded,
                    color: sim.isDefault ? const Color(0xFFF59E0B) : brandColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'شريحة ${index + 1}: ${sim.phoneNumber.isNotEmpty ? sim.phoneNumber : sim.port}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sim.port,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 9.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Solde: ${sim.balance}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Badges: License Status + Default SIM indicator
                  if (sim.isDefault && isSimActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        '⭐ إفتراضية',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Button to make default (ONLY ALLOWED IF ACTIVE!)
                    InkWell(
                      onTap: () {
                        if (!isSimActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ لا يمكن تعيين شريحة غير مفعلة كإفتراضية. يرجى تفعيل الشريحة أولاً.'),
                              backgroundColor: AppColors.warning,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        gsmProvider.setDefaultSim(sim.port);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تعيين الشريحة ${sim.phoneNumber} (Port ${sim.port}) كشريحة إفتراضية للفليكسي.'),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isSimActive ? const Color(0xFF1E293B) : const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSimActive ? const Color(0xFF334155) : const Color(0xFF1E293B)),
                        ),
                        child: Text(
                          'تعيين كإفتراضي',
                          style: TextStyle(
                            color: isSimActive ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSimActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSimActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isSimActive ? '⚡ مفعلة' : '🔒 غير مفعلة',
                      style: TextStyle(
                        color: isSimActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Accordion Expanded Body
          if (isExpanded) ...[
            const Divider(color: Color(0xFF1E293B), height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCapsule(isSimActive, statusLabel, expiryStr),

                  const SizedBox(height: 12),

                  _buildFieldLabel('Numéro ICCID (Lecture Auto)'),
                  const SizedBox(height: 6),
                  _buildReadOnlyBox(
                    value: sim.iccid,
                    fieldLabel: 'رقم ICCID',
                    brandColor: brandColor,
                    suffixIcon: Icons.qr_code_scanner_rounded,
                  ),

                  const SizedBox(height: 12),

                  _buildFieldLabel('Numéro de Téléphone à Activer'),
                  const SizedBox(height: 6),
                  _buildReadOnlyBox(
                    value: sim.phoneNumber,
                    fieldLabel: 'رقم الهاتف',
                    brandColor: brandColor,
                    suffixIcon: Icons.phone_android_rounded,
                  ),

                  const SizedBox(height: 12),

                  _buildSerialBoxHeader(codeController.text, isSimActive),
                  const SizedBox(height: 6),
                  _buildEditableCodeBox(
                    controller: codeController,
                    hintText: 'Entrez le code d\'activation pour cette SIM (ex: FX1.eyJ...)',
                    brandColor: brandColor,
                    isReadOnly: isSimActive,
                  ),

                  const SizedBox(height: 18),

                  _buildActivationButton(
                    isSimActive: isSimActive,
                    isLoading: isLoading,
                    brandColor: brandColor,
                    onActivate: () => _handleActivate(
                      operatorId: operatorId,
                      operatorName: sim.operatorName,
                      iccid: sim.iccid,
                      phone: sim.phoneNumber,
                      port: sim.port,
                      code: codeController.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Sub-Widgets Helpers ---
  Widget _buildStatusCapsule(bool isSimActive, String statusLabel, String? expiryStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSimActive
            ? const Color(0xFF10B981).withValues(alpha: 0.12)
            : const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSimActive
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSimActive ? Icons.verified_rounded : Icons.lock_outline_rounded,
            color: isSimActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSimActive ? 'حالة الشريحة: مفعلة ومرخصة ⚡' : 'حالة الشريحة: $statusLabel',
                  style: TextStyle(
                    color: isSimActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSimActive && expiryStr != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'صلاحية الترخيص حتى: $expiryStr',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialBoxHeader(String currentCode, bool isSimActive) {
    return Row(
      children: [
        Expanded(
          child: _buildFieldLabel('Code d\'activation (Serial)'),
        ),
        if (currentCode.trim().isNotEmpty) ...[
          Tooltip(
            message: 'نسخ كود السيريال',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _copyToClipboard(currentCode, 'كود السيريال'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, color: Color(0xFF60A5FA), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'نسخ السيريال',
                      style: TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (isSimActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'مقروء فقط 🔒',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivationButton({
    required bool isSimActive,
    required bool isLoading,
    required Color brandColor,
    required VoidCallback onActivate,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: isSimActive || isLoading ? null : onActivate,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSimActive ? const Color(0xFF10B981).withValues(alpha: 0.15) : brandColor,
          foregroundColor: isSimActive ? const Color(0xFF10B981) : Colors.white,
          disabledBackgroundColor: isSimActive ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF1E293B),
          disabledForegroundColor: isSimActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
          elevation: 0,
          side: isSimActive
              ? BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSimActive ? 'PUCE ACTIVÉE ET VÉRIFIÉE' : 'ACTIVER LA PUCE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isSimActive ? const Color(0xFF10B981) : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isSimActive ? Icons.verified_rounded : Icons.bolt_rounded,
                    size: 18,
                    color: isSimActive ? const Color(0xFF10B981) : Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildReadOnlyBox({
    required String value,
    required String fieldLabel,
    required Color brandColor,
    required IconData suffixIcon,
  }) {
    final isValid = value.isNotEmpty && !value.contains('Non') && !value.contains('Lecture');
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF070D1B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(
            suffixIcon,
            color: brandColor.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
            ),
          ),
          Tooltip(
            message: 'نسخ $fieldLabel (Copier)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _copyToClipboard(value, fieldLabel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isValid
                        ? brandColor.withValues(alpha: 0.15)
                        : const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isValid
                          ? brandColor.withValues(alpha: 0.35)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: isValid ? Colors.white : const Color(0xFF64748B),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'نسخ',
                        style: TextStyle(
                          color: isValid ? Colors.white : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCodeBox({
    required TextEditingController controller,
    required String hintText,
    required Color brandColor,
    required bool isReadOnly,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFF070D1B).withValues(alpha: 0.7) : const Color(0xFF070D1B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReadOnly
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFF1E293B),
          width: isReadOnly ? 1.2 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: 3,
        minLines: 2,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          color: isReadOnly ? const Color(0xFF10B981) : Colors.white,
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 11,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: InputBorder.none,
          suffixIcon: isReadOnly
              ? const Icon(
                  Icons.key_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildOperatorLogo(int operatorId) {
    if (operatorId == 1) {
      // Djezzy
      return Container(
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE52E2E),
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFFE52E2E), Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('DJEZZY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              Text('جازي', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else if (operatorId == 2) {
      // Mobilis
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F261C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('موبيليس', style: TextStyle(color: Color(0xFFE52E2E), fontSize: 8, fontWeight: FontWeight.bold)),
            Text('mobilis', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
      );
    } else {
      // Ooredoo
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF261217),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE52E2E).withValues(alpha: 0.4)),
        ),
        child: const Text('ooredoo', style: TextStyle(color: Color(0xFFE52E2E), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      );
    }
  }

  // --- Bottom Pipeline Checklist Card ---
  Widget _buildProcessPipelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF60A5FA),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Guide d\'activation & Utilisation Multi-SIM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  _buildPipelineStep(
                    stepNum: '1',
                    title: 'Brancher les Modems GSM',
                    desc: 'Connectez 1 ou plusieurs clés USB (Mobilis, Djezzy, Ooredoo) sur les ports COM.',
                    width: isNarrow ? double.infinity : (constraints.maxWidth - 48) / 3,
                  ),
                  _buildPipelineStep(
                    stepNum: '2',
                    title: 'Gérer les Cartes via Accordéon',
                    desc: 'Chaque carte SIM est identifiée par son ICCID. Cliquez sur l\'accordéon pour afficher ses détails.',
                    width: isNarrow ? double.infinity : (constraints.maxWidth - 48) / 3,
                  ),
                  _buildPipelineStep(
                    stepNum: '3',
                    title: 'Sélectionner la SIM par Défaut',
                    desc: 'Si une seule SIM est activée, elle est prise automatiquement par défaut pour les transferts Flexy.',
                    width: isNarrow ? double.infinity : (constraints.maxWidth - 48) / 3,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required String stepNum,
    required String title,
    required String desc,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.6)),
            ),
            child: Center(
              child: Text(
                stepNum,
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalMiniBars extends StatelessWidget {
  final Color color;
  final int bars;

  const _SignalMiniBars({
    required this.color,
    required this.bars,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(4, 1 <= bars),
        const SizedBox(width: 2),
        _bar(7, 2 <= bars),
        const SizedBox(width: 2),
        _bar(10, 3 <= bars),
        const SizedBox(width: 2),
        _bar(13, 4 <= bars),
      ],
    );
  }

  Widget _bar(double height, bool active) {
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: active ? color : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
