import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';

class AccessDeniedView extends StatelessWidget {
  final String? requiredPermission;
  final VoidCallback? onGoBack;
  final VoidCallback? onGoDashboard;

  const AccessDeniedView({
    super.key,
    this.requiredPermission,
    this.onGoBack,
    this.onGoDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('access_denied_title'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                context.tr('access_denied_message'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            if (requiredPermission != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardHover,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Permission requise: $requiredPermission',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.amberAccent,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onGoBack != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(context.tr('go_back')),
                    onPressed: onGoBack,
                  ),
                if (onGoBack != null && onGoDashboard != null)
                  const SizedBox(width: 16),
                if (onGoDashboard != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.dashboard_outlined, size: 18),
                    label: Text(
                      context.tr('go_dashboard'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: onGoDashboard,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
