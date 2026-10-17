import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/gsm_provider.dart';
import '../../providers/license_provider.dart';

class GsmSimCardsBar extends StatelessWidget {
  final int selectedModemIndex;
  final Function(int)? onSelectModem;

  const GsmSimCardsBar({
    super.key,
    this.selectedModemIndex = 2,
    this.onSelectModem,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<GsmProvider, LicenseProvider>(
      builder: (context, gsmProvider, licenseProvider, _) {
        final List<Widget> cardWidgets = [];

        // Build list of cards for all operators (Ooredoo: 3, Djezzy: 1, Mobilis: 2)
        for (int opId in [3, 1, 2]) {
          final sims = gsmProvider.getSimsForOperator(opId);
          final opName = (opId == 1) ? 'DJEZZY' : ((opId == 2) ? 'MOBILIS' : 'OOREDOO');
          final brandColor = (opId == 1)
              ? const Color(0xFFF59E0B)
              : (opId == 2 ? const Color(0xFF00E6A8) : const Color(0xFFEF4444));
          final accentBg = (opId == 1)
              ? const Color(0xFF241C10)
              : (opId == 2 ? const Color(0xFF0E241A) : const Color(0xFF261217));

          if (sims.isEmpty) {
            // Disconnected card placeholder
            cardWidgets.add(
              _GsmSimCardItem(
                operatorId: opId,
                operatorName: opName,
                phoneMask: opId == 1 ? '07XX ▪▪ ▪▪ 12' : (opId == 2 ? '06XX ▪▪ ▪▪ 67' : '05XX ▪▪ ▪▪ 89'),
                comPort: '--',
                brandColor: brandColor,
                accentBgColor: accentBg,
                isSelected: false,
                isConnected: false,
                isDefault: false,
                isLicenseActive: false,
                signalBarsCount: 0,
                rawRssi: 0,
                isRefreshing: false,
                onTap: () => onSelectModem?.call(opId == 3 ? 0 : (opId == 1 ? 1 : 2)),
                soldeValue: 'Non connecté',
                soldeLabel: opId == 2 ? 'POSTE' : 'SOLDE',
                onRefresh: () => gsmProvider.refreshOperatorModem(opId),
                onToggleDisconnect: () => gsmProvider.toggleConnection(opId),
              ),
            );
          } else {
            // Render each physical connected SIM
            for (var sim in sims) {
              final isSimActive = licenseProvider.isIccidActivated(sim.iccid);
              cardWidgets.add(
                _GsmSimCardItem(
                  operatorId: opId,
                  operatorName: opName,
                  phoneMask: sim.maskedPhone,
                  comPort: sim.port,
                  brandColor: brandColor,
                  accentBgColor: accentBg,
                  isSelected: sim.isDefault,
                  isConnected: true,
                  isDefault: sim.isDefault,
                  isLicenseActive: isSimActive,
                  signalBarsCount: sim.signalLevel,
                  rawRssi: sim.rawRssi,
                  isRefreshing: sim.isRefreshing,
                  onTap: () {
                    if (isSimActive) {
                      gsmProvider.setDefaultSim(sim.port);
                    }
                    onSelectModem?.call(opId == 3 ? 0 : (opId == 1 ? 1 : 2));
                  },
                  soldeValue: sim.balance,
                  soldeLabel: opId == 2 ? 'POSTE' : 'SOLDE',
                  onRefresh: () => gsmProvider.refreshSim(sim.port),
                  onToggleDisconnect: () => gsmProvider.toggleConnection(opId),
                ),
              );
            }
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: cardWidgets
                .expand((widget) => [widget, const SizedBox(width: 10)])
                .take(cardWidgets.length * 2 - 1)
                .toList(),
          ),
        );
      },
    );
  }
}

class _GsmSimCardItem extends StatelessWidget {
  final int operatorId;
  final String operatorName;
  final String phoneMask;
  final String comPort;
  final Color brandColor;
  final Color accentBgColor;
  final bool isSelected;
  final bool isConnected;
  final bool isDefault;
  final bool isLicenseActive;
  final int signalBarsCount;
  final int rawRssi;
  final bool isRefreshing;
  final VoidCallback onTap;
  final String soldeValue;
  final String soldeLabel;
  final VoidCallback onRefresh;
  final VoidCallback onToggleDisconnect;

  const _GsmSimCardItem({
    required this.operatorId,
    required this.operatorName,
    required this.phoneMask,
    required this.comPort,
    required this.brandColor,
    required this.accentBgColor,
    required this.isSelected,
    required this.isConnected,
    required this.isDefault,
    required this.isLicenseActive,
    required this.signalBarsCount,
    required this.rawRssi,
    required this.isRefreshing,
    required this.onTap,
    required this.soldeValue,
    required this.soldeLabel,
    required this.onRefresh,
    required this.onToggleDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected ? const Color(0xFF00E6A8) : AppColors.danger;

    final int dBm = (!isConnected || rawRssi == 0 || rawRssi == 99) ? -113 : (-113 + (rawRssi * 2));
    final int percentage = (!isConnected || rawRssi == 0 || rawRssi == 99) ? 0 : ((rawRssi / 31.0) * 100).round();
    final tooltipMsg = isConnected
        ? 'Signal $operatorName ($comPort): RSSI $rawRssi/31 ($dBm dBm, $percentage%)'
        : 'Aucun signal (Non connecté)';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isConnected ? const Color(0xFF111726) : const Color(0xFF0C101A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? brandColor
                : (isConnected ? AppColors.border : AppColors.border.withValues(alpha: 0.4)),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Opacity(
          opacity: isConnected ? 1.0 : 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Phone Mask + Operator Name + Status Dot + Badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      phoneMask,
                      style: TextStyle(
                        color: isConnected ? const Color(0xFF6B7280) : const Color(0xFF4B5563),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isDefault && isConnected && isLicenseActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 10),
                          SizedBox(width: 2),
                          Text(
                            'DÉFAUT',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    operatorName,
                    style: TextStyle(
                      color: isConnected ? brandColor : brandColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Refresh Sync Icon
                  InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(10),
                    child: isRefreshing
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: brandColor,
                            ),
                          )
                        : const Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF6B7280),
                            size: 13,
                          ),
                  ),

                  const SizedBox(width: 3),

                  // Live Connection Status Dot
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: isConnected
                          ? [
                              BoxShadow(
                                color: statusColor,
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Real-Time Signal Bars + Real COM Port Label + License Badge
              Row(
                children: [
                  Tooltip(
                    message: tooltipMsg,
                    child: _SignalBarsWidget(
                      brandColor: brandColor,
                      activeBarsCount: isConnected ? signalBarsCount : 0,
                      isConnected: isConnected,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isConnected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isLicenseActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.18)
                            : const Color(0xFFEF4444).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isLicenseActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : const Color(0xFFEF4444).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        isLicenseActive ? '⚡ مفعلة' : 'غير مفعلة',
                        style: TextStyle(
                          color: isLicenseActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    comPort,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Solde / Balance + Disconnect or Balance Action
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isConnected ? accentBgColor : const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        soldeValue,
                        style: TextStyle(
                          color: isConnected ? brandColor : const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? (operatorId == 2
                              ? const Color(0xFF064E3B)
                              : (operatorId == 1 ? const Color(0xFF78350F) : const Color(0xFF7F1D1D)))
                          : const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isConnected ? soldeLabel : 'DISCON',
                      style: TextStyle(
                        color: isConnected ? brandColor : const Color(0xFFEF4444),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Mini Bottom Action Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniIconButton(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'Ouvrir Terminal AT ($comPort)',
                    onTap: () {},
                  ),
                  _MiniIconButton(
                    icon: Icons.tag_rounded,
                    tooltip: 'Consulter Solde USSD ($comPort)',
                    onTap: onRefresh,
                  ),
                  _MiniIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Réinitialiser Connexion ($comPort)',
                    onTap: onRefresh,
                  ),
                  _MiniIconButton(
                    icon: Icons.power_settings_new_rounded,
                    tooltip: isConnected ? 'Déconnecter ($comPort)' : 'Reconnecter ($comPort)',
                    onTap: onToggleDisconnect,
                    iconColor: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 26,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2234),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            size: 13,
            color: iconColor ?? const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _SignalBarsWidget extends StatelessWidget {
  final Color brandColor;
  final int activeBarsCount;
  final bool isConnected;

  const _SignalBarsWidget({
    required this.brandColor,
    required this.activeBarsCount,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBars = isConnected ? activeBarsCount : 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(4, 1 <= effectiveBars),
        const SizedBox(width: 2),
        _buildBar(7, 2 <= effectiveBars),
        const SizedBox(width: 2),
        _buildBar(10, 3 <= effectiveBars),
        const SizedBox(width: 2),
        _buildBar(13, 4 <= effectiveBars),
      ],
    );
  }

  Widget _buildBar(double height, bool isActive) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? brandColor : const Color(0xFF374151),
        borderRadius: BorderRadius.circular(1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.6),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ]
            : [],
      ),
    );
  }
}
