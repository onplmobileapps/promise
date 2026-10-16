import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

/// An iOS-style keyboard accessory toolbar ("Done" bar) that appears
/// above the soft keyboard on iOS devices and dismisses the keyboard when "Done" is tapped.
class IosKeyboardDoneBar extends StatelessWidget {
  const IosKeyboardDoneBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isIos =
        Theme.of(context).platform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isIos) return child;

    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Stack(
      children: [
        child,
        if (keyboardHeight > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: Material(
              type: MaterialType.transparency,
              child: const _IosDoneBar(),
            ),
          ),
      ],
    );
  }
}

class _IosDoneBar extends StatelessWidget {
  const _IosDoneBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return Container(
      height: 44.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline, width: 0.5),
          bottom: BorderSide(color: colors.outline, width: 0.5),
        ),
        boxShadow: context.elevations.raised,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: TextButton.styleFrom(
                foregroundColor: colors.primaryShade,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Done',
                style: text.labelLarge?.copyWith(
                  color: colors.primaryShade,
                  fontWeight: AppFonts.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
