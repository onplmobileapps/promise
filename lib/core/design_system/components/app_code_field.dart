import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A one-time code typed into [length] cells, one digit each. The digits
/// go into [controller] through an unseen field, so the keyboard, pasting
/// and the phone's code autofill all work; the cells show them, the next
/// one to fill outlined while it has focus. [onCompleted] runs once every
/// cell is filled.
class AppCodeField extends StatefulWidget {
  const AppCodeField({
    super.key,
    required this.length,
    required this.controller,
    this.focusNode,
    this.onCompleted,
  });

  final int length;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onCompleted;

  @override
  State<AppCodeField> createState() => _AppCodeFieldState();
}

class _AppCodeFieldState extends State<AppCodeField> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.removeListener(_changed);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final code = widget.controller.text;
    final focused = _focus.hasFocus;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _focus.requestFocus();
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.length; i++) ...[
            if (i > 0) AppSpacing.gapSm,
            AnimatedContainer(
              duration: AppMotion.short,
              width: AppSizes.otpCellWidth,
              height: AppSizes.otpCellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < code.length || (focused && i == code.length)
                    ? colors.surface
                    : colors.surfaceSunken,
                borderRadius: AppRadius.borderMd,
                border: focused && i == code.length
                    ? Border.all(color: colors.focus, width: 1.5)
                    : Border.all(
                        color: i < code.length
                            ? colors.outlineStrong
                            : colors.outline,
                      ),
              ),
              child: Text(
                i < code.length ? code[i] : '',
                style: text.headlineSmall,
              ),
            ),
          ],
          // Takes the typing; a point wide and unseen.
          SizedBox(
            width: 1,
            height: AppSizes.otpCellHeight,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                enableInteractiveSelection: false,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  if (value.length == widget.length) {
                    widget.onCompleted?.call(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
