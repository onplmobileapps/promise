import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/field_rules.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_states.dart';
import 'package:railway_hrms/modules/auth/widgets/biometric_sign_in_button.dart';

/// The longest employee ID and password the form takes.
const employeeIdMaxLength = 10;
const passwordMaxLength = 20;

/// PROMISE sign-in for employees: employee ID and password, or Face ID or
/// a fingerprint once biometric sign-in is on. Needs an [AuthCubit] above it.
class EmployeeSignInForm extends StatefulWidget {
  const EmployeeSignInForm({
    super.key,
    required this.onSignedIn,
    this.biometrics,
    this.compact = false,
    this.tight = false,
  });

  /// Called once the employee is signed in.
  final VoidCallback onSignedIn;

  /// Defaults to the app's registered authenticator.
  final BiometricAuthenticator? biometrics;

  /// Short of room: the note under the biometric key steps aside and the
  /// gaps tighten.
  final bool compact;

  /// Tighter still: the eyebrow over the card's heading steps aside too.
  final bool tight;

  @override
  State<EmployeeSignInForm> createState() => _EmployeeSignInFormState();
}

class _EmployeeSignInFormState extends State<EmployeeSignInForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  late final BiometricAuthenticator _biometrics =
      widget.biometrics ?? sl<BiometricAuthenticator>();

  bool _obscurePassword = true;

  /// The form shaking its head at a failed sign-in.
  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.shake,
  );

  /// The face or fingerprint set up on the phone; none, no key for it.
  BiometricKind? _biometric;

  /// The password as it was, to tell typing from autofill.
  String _password = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _passwordController.addListener(_onPasswordChanged);
  }

  /// Signs in by itself when a saved password is filled in: the keyboard's
  /// or the phone's autofill puts it in all at once, where typing adds a
  /// letter at a time and leaves the button to the employee.
  void _onPasswordChanged() {
    final before = _password;
    final now = _passwordController.text;
    _password = now;
    final filledAtOnce = before.isEmpty && now.length > 1;
    if (!filledAtOnce || _employeeIdController.text.trim().isEmpty) return;
    // After the fill has finished and the fields show it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _passwordController.text == now) _submit();
    });
  }

  Future<void> _checkBiometrics() async {
    final biometric = await _biometrics.enrolled();
    if (mounted) setState(() => _biometric = biometric);
  }

  @override
  void dispose() {
    _shake.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _employeeIdController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    // Once at a time, whether autofill or the button started it.
    if (context.read<AuthCubit>().state is AuthLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
      _employeeIdController.text.trim(),
      _passwordController.text,
    );
  }

  /// Signs in with the credentials saved at the last sign-in, once the
  /// employee's face or fingerprint checks out.
  Future<void> _signInWithBiometrics() async {
    final l10n = context.l10n;
    if (!await StorageService.isBiometricEnabled()) {
      if (!mounted) return;
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        glyph: AppGlyphs.fingerprint,
        title: l10n.biometricDisabledTitle,
        message: l10n.biometricDisabledMessage,
        primaryLabel: l10n.actionGotIt,
      );
      return;
    }
    if (!await _biometrics.authenticate(reason: l10n.biometricReason)) return;
    final credentials = await StorageService.getUserCredentials();
    if (!mounted) return;
    final employeeId = credentials?['empID']?.trim() ?? '';
    final password = credentials?['password'] ?? '';
    if (employeeId.isEmpty || password.isEmpty) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.biometricNoCredentialsTitle,
        message: l10n.biometricNoCredentialsMessage,
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(employeeId, password);
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      _formKey.currentState?.reset();
      _passwordController.clear();
      widget.onSignedIn();
    } else if (state is AuthError) {
      final l10n = context.l10n;
      if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
      showAppDialog(
        context: context,
        tone: AppDialogTone.error,
        title: l10n.loginFailedTitle,
        message: state.error,
        primaryLabel: l10n.actionOk,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final biometric = _biometric;
    return BlocListener<AuthCubit, AuthState>(
      listener: _onAuthState,
      child: AnimatedBuilder(
        animation: _shake,
        // A few swings either side, dying away.
        builder: (context, child) => Transform.translate(
          offset: Offset(
            math.sin(_shake.value * math.pi * 6) *
                AppSizes.shakeDistance *
                (1 - _shake.value),
            0,
          ),
          child: child,
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A little in from the card's edge, in line with the
                // fields' own insides.
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.tight) ...[
                        Text(
                          l10n.loginEyebrow,
                          style: text.labelSmall?.copyWith(
                            color: colors.iconAccent,
                            fontWeight: AppFonts.bold,
                            letterSpacing: AppSizes.eyebrowTracking,
                          ),
                        ),
                        AppSpacing.gapXs,
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.loginCardTitle,
                          style: text.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                widget.compact ? AppSpacing.gapMd : AppSpacing.gapLg,
                if (biometric != null) ...[
                  BiometricSignInButton(
                    kind: biometric,
                    onPressed: _signInWithBiometrics,
                  ),
                  if (!widget.compact) ...[
                    AppSpacing.gapSm,
                    Text(
                      l10n.loginBiometricNote,
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ],
                  widget.compact ? AppSpacing.gapMd : AppSpacing.gapLg,
                  _OrDivider(
                    l10n.loginOrPassword(
                      l10n.employeeIdLabel,
                      l10n.passwordLabel,
                    ),
                    bold: [l10n.employeeIdLabel, l10n.passwordLabel],
                  ),
                  AppSpacing.gapLg,
                ],
                // Keyed, as are the password and the key under them: the
                // notes around them come and go as the keyboard opens, and
                // unkeyed they would be built anew, losing focus and closing
                // the keyboard again.
                AppTextField(
                  key: const ValueKey('employee-id'),
                  controller: _employeeIdController,
                  label: l10n.employeeIdLabel,
                  hint: l10n.employeeIdHint,
                  glyph: AppGlyphs.idCard,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  inputFormatters: FieldInput.noSpaces(
                    maxLength: employeeIdMaxLength,
                  ),
                  validator: FieldRules.all([
                    FieldRules.required(l10n.employeeIdRequired),
                    FieldRules.maxLength(
                      employeeIdMaxLength,
                      l10n.employeeIdTooLong(employeeIdMaxLength),
                    ),
                  ]),
                ),
                AppSpacing.gapMd,
                AppTextField(
                  key: const ValueKey('password'),
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: l10n.passwordLabel,
                  hint: l10n.passwordHint,
                  glyph: AppGlyphs.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  inputFormatters: FieldInput.noSpaces(
                    maxLength: passwordMaxLength,
                  ),
                  validator: FieldRules.all([
                    FieldRules.required(l10n.passwordRequired),
                    FieldRules.maxLength(
                      passwordMaxLength,
                      l10n.passwordTooLong(passwordMaxLength),
                    ),
                  ]),
                  suffix: AppVisibilityToggle(
                    visible: !_obscurePassword,
                    showLabel: l10n.passwordShow,
                    hideLabel: l10n.passwordHide,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                widget.tight
                    ? AppSpacing.gapMd
                    : widget.compact
                    ? AppSpacing.gapLg
                    : AppSpacing.gapXl,
                BlocBuilder<AuthCubit, AuthState>(
                  key: const ValueKey('sign-in'),
                  buildWhen: (previous, current) =>
                      (previous is AuthLoading) != (current is AuthLoading),
                  // Under a face or fingerprint key, the password's is the
                  // second way in.
                  builder: (context, state) => AppButton(
                    label: biometric == null
                        ? l10n.loginButton
                        : l10n.loginWithPassword,
                    variant: biometric == null
                        ? AppButtonVariant.primary
                        : AppButtonVariant.tonal,
                    size: AppButtonSize.medium,
                    loadingLabel: l10n.loginInProgress,
                    isLoading: state is AuthLoading,
                    onPressed: _submit,
                  ),
                ),
                // The way back in for a forgotten password, under the
                // keys, on every phone; short of room, its own touch area
                // is the gap.
                if (!widget.compact) AppSpacing.gapSm,
                Center(
                  child: _ForgotPasswordLink(
                    label: l10n.loginForgotPassword,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.forgotPassword),
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

/// A hairline either side of [label], between two ways in, the words in
/// [bold] set bold.
class _OrDivider extends StatelessWidget {
  const _OrDivider(this.label, {this.bold = const []});

  final String label;
  final List<String> bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final line = Expanded(child: Divider(height: 1, color: colors.outline));
    final strong = TextStyle(
      color: colors.textPrimary,
      fontWeight: AppFonts.bold,
    );
    // The label cut at each bold word, the words kept.
    final pattern = RegExp(bold.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var at = 0;
    if (bold.isNotEmpty) {
      for (final match in pattern.allMatches(label)) {
        spans
          ..add(TextSpan(text: label.substring(at, match.start)))
          ..add(TextSpan(text: match[0], style: strong));
        at = match.end;
      }
    }
    spans.add(TextSpan(text: label.substring(at)));
    // The words take what they need, up to most of the row, and the lines
    // share the rest evenly, so the words sit in the middle.
    return LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          line,
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: box.maxWidth * 0.8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              // On one line always, smaller if it must be.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(children: spans),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

/// "Forgot password?" in jade beside a small 3D lock, a soft pill lighting
/// up under the finger: a link, quieter than the keys above it, with a
/// full-size touch area.
class _ForgotPasswordLink extends StatefulWidget {
  const _ForgotPasswordLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_ForgotPasswordLink> createState() => _ForgotPasswordLinkState();
}

class _ForgotPasswordLinkState extends State<_ForgotPasswordLink> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.enter,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: _pressed
                    ? colors.primaryContainer
                    : colors.primaryContainer.withValues(alpha: 0),
                borderRadius: AppRadius.borderPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppGlyphIcon(
                    AppGlyphs.lock,
                    depth: true,
                    size: AppSizes.iconSm,
                    color: colors.iconAccent,
                  ),
                  AppSpacing.gapXs,
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: colors.accent,
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
