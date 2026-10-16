import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AppDialogs {
  // ─── Shared bottom-sheet style dialog shell ─────────────────────────────────
  static Future<T?> _showBottomDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext dialogContext) builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, widget) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
            child: widget,
          ),
        );
      },
      // ctx is the dialog's own BuildContext — Navigator.of(ctx) closes the dialog.
      pageBuilder: (ctx, _, _) =>
          _dialogShell(context: ctx, child: builder(ctx)),
    );
  }

  // ─── Modern dialog shell — always uses the dialog's own context ────────────
  static Widget _dialogShell({
    required BuildContext context,
    required Widget child,
  }) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── Coming Soon Dialog ─────────────────────────────────────────────────────
  /// Says [feature] isn't available yet, instead of opening it.
  static Future<void> showComingSoonDialog(
    BuildContext context, {
    required String feature,
  }) {
    const green = Color(0xFF5CA38E);
    const greenDark = Color(0xFF3E8A74);
    return _showBottomDialog(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE6F4EF), Color(0xFFCDE9DF)],
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: greenDark,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: greenDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              feature,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're putting the finishing touches on $feature. It will be "
              'available in an upcoming update.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Location Service Dialog ────────────────────────────────────────────────
  static Future<void> showLocationServiceDialog(BuildContext context) {
    return _showBottomDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IconDialog(
        icon: Icons.location_off_rounded,
        iconColor: const Color(0xFFE53935),
        title: 'Location Disabled',
        message:
            'Location services are disabled on your device. Enable them to continue with face verification.',
        primaryLabel: 'Enable in Settings',
        onPrimary: () {
          Geolocator.openLocationSettings();
          Navigator.of(ctx).pop();
        },
        onSecondary: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  // ─── Response Dialog (attendance success / error) ───────────────────────────
  static Future<void> showResponseDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? status,
    Map<String, dynamic>? data,
    required bool isSuccess,
  }) {
    final accentColor = isSuccess
        ? const Color(0xFF015E35)
        : const Color(0xFFE53935);

    return _showBottomDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Accent header strip ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                if (status != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
                if (data != null && data.containsKey('employee_id')) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.badge_rounded,
                    'Employee ID',
                    data['employee_id'].toString(),
                    accentColor,
                  ),
                ],
              ],
            ),
          ),

          // ── Action ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isSuccess ? 'Done' : 'OK',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  static Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable: Icon + message confirm ────────────────────────────────────────

class _IconDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _IconDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (onSecondary != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    primaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
