import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/license_provider.dart';
import 'gsm_sim_cards_bar.dart';

class FlexyTopHeader extends StatelessWidget {
  final String pageTitle;
  final String pageSubtitle;

  const FlexyTopHeader({
    super.key,
    this.pageTitle = 'Flexy / Recharge',
    this.pageSubtitle = 'Transferts d’argent rapides et sécurisés',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left Title Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    pageTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Real-Time Socket.IO Status Badge
                  Consumer<LicenseProvider>(
                    builder: (context, licProvider, _) {
                      final isConnected = licProvider.isSocketConnected;
                      final isOnline = licProvider.isOnline;

                      Color badgeColor;
                      Color badgeBg;
                      String label;
                      IconData icon;

                      if (isConnected) {
                        badgeColor = const Color(0xFF10B981);
                        badgeBg = const Color(0xFF064E3B).withValues(alpha: 0.4);
                        label = 'Live Sync (Real-Time)';
                        icon = Icons.bolt_rounded;
                      } else if (isOnline) {
                        badgeColor = const Color(0xFF3B82F6);
                        badgeBg = const Color(0xFF1E3A8A).withValues(alpha: 0.4);
                        label = 'Online (HTTP)';
                        icon = Icons.cloud_done_rounded;
                      } else if (licProvider.showAdminOnlineReminder) {
                        badgeColor = const Color(0xFFF59E0B);
                        badgeBg = const Color(0xFF78350F).withValues(alpha: 0.4);
                        label = 'Offline (Vérification recommandée)';
                        icon = Icons.info_outline_rounded;
                      } else {
                        badgeColor = const Color(0xFF10B981);
                        badgeBg = const Color(0xFF064E3B).withValues(alpha: 0.4);
                        label = 'Offline (Actif ⚡)';
                        icon = Icons.check_circle_outline_rounded;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pageSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Right: Rich Cyber 3 GSM SIM Cards Bar (Ooredoo, Djezzy, Mobilis)
          const Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GsmSimCardsBar(),
            ),
          ),
        ],
      ),
    );
  }
}
