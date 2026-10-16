import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/components/app_field_frame.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The design's text field: a pressed-in well with a line [glyph], its
/// [label] inside above what is typed, and an optional [suffix] action such
/// as "show password". It validates as part of a [Form], like a
/// `TextFormField`, and shows its error below the well.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.label,
    this.hint,
    this.glyph,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.autovalidateMode,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final AppGlyph? glyph;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  /// Lines it opens with and may grow to; one by default, like a name.
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownFocus;
  bool _focused = false;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    final was = old.focusNode ?? _ownFocus;
    if (was != _focus) {
      was?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _focus.hasFocus) setState(() => _focused = _focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return _TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) {
        final state = field as _TextFormFieldState;
        // A tap anywhere on the field puts the cursor in it, not only on
        // the line of text.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _focus.requestFocus : null,
          child: AppFieldFrame(
            label: widget.label,
            glyph: widget.glyph,
            trailing: widget.suffix,
            error: field.errorText,
            state: !widget.enabled
                ? AppFieldState.disabled
                : field.hasError
                ? AppFieldState.error
                : _focused
                ? AppFieldState.focused
                : AppFieldState.idle,
            // The label and the input are read as one field.
            child: MergeSemantics(
              child: Semantics(
                label: widget.label,
                child: TextField(
                  controller: state.controller,
                  focusNode: _focus,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  onSubmitted: widget.onFieldSubmitted,
                  autofillHints: widget.autofillHints,
                  enabled: widget.enabled,
                  minLines: widget.minLines,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  onChanged: (value) {
                    field.didChange(value);
                    widget.onChanged?.call(value);
                  },
                  style: text.labelLarge?.copyWith(color: colors.textPrimary),
                  cursorColor: colors.textPrimary,
                  // The frame draws the well; the input itself is bare.
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: text.labelLarge?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A form field over a text controller, kept in step with it both ways, as
/// `TextFormField` keeps its own.
class _TextFormField extends FormField<String> {
  _TextFormField({
    required this.controller,
    required super.builder,
    super.validator,
    super.autovalidateMode,
    super.enabled,
  }) : super(initialValue: controller?.text ?? '');

  final TextEditingController? controller;

  @override
  FormFieldState<String> createState() => _TextFormFieldState();
}

class _TextFormFieldState extends FormFieldState<String> {
  TextEditingController? _own;

  _TextFormField get _field => widget as _TextFormField;

  TextEditingController get controller => _field.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (_field.controller == null) {
      _own = TextEditingController(text: widget.initialValue);
    }
    controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(_TextFormField old) {
    super.didUpdateWidget(old);
    if (old.controller == _field.controller) return;
    (old.controller ?? _own)?.removeListener(_onControllerChanged);
    if (_field.controller == null && _own == null) {
      _own = TextEditingController(text: old.controller?.text);
    }
    controller.addListener(_onControllerChanged);
    setValue(controller.text);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _own?.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (controller.text != value) controller.text = value ?? '';
  }

  @override
  void reset() {
    // Clear the controller first, so its listener has nothing to report.
    controller.text = widget.initialValue ?? '';
    super.reset();
  }

  /// Text set on the controller by code, not typed, still counts.
  void _onControllerChanged() {
    if (controller.text != value) didChange(controller.text);
  }
}
