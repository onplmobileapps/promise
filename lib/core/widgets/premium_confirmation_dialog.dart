import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';

class PremiumConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const PremiumConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Stay',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showCancel = cancelLabel.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    final Color accent = isDestructive ? cs.error : cs.primary;
    final Color accentContainer = isDestructive
        ? cs.errorContainer
        : cs.primaryContainer;
    final Color onAccentContainer = isDestructive
        ? cs.onErrorContainer
        : cs.onPrimaryContainer;

    final lite = AppPerformance.flatOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.08).clamp(16, 40),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        // Solid where the phone can't spare the blur.
        child: BackdropFilter(
          enabled: !lite,
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: lite ? 1 : 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with a soft glow ring behind it instead of a
                      // flat filled circle — gives it depth/premium feel.
                      SizedBox(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accentContainer.withValues(alpha: 0.9),
                                    accentContainer.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                              child: Icon(
                                icon,
                                size: 30,
                                color: onAccentContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      if (showCancel) ...[
                        Expanded(
                          child: _DialogActionButton(
                            label: cancelLabel,
                            color: cs.onSurfaceVariant,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ],
                      Expanded(
                        child: _DialogActionButton(
                          label: confirmLabel,
                          color: accent,
                          bold: true,
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;
  final VoidCallback onPressed;

  const _DialogActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: BorderRadius.zero,
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
