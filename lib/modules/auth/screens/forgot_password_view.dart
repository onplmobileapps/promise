import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/utils/validators.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';
import 'package:railway_hrms/modules/auth/widgets/auth_scaffold.dart';

/// Asks for the email address to reset the password.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final repository = sl<AuthRepository>();

    final result = await repository.forgotPassword(email);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        showAppDialog(
          context: context,
          tone: AppDialogTone.error,
          title: l10n.messageErrorTitle,
          message: failure.message,
          primaryLabel: l10n.actionOk,
        );
      },
      (response) {
        String msg =
            'Password reset instructions have been sent to your email.';
        final data = response.data;
        if (data is Map) {
          msg =
              data['message']?.toString() ??
              data['msg']?.toString() ??
              data['detail']?.toString() ??
              data['Success']?.toString() ??
              msg;
        }

        showAppDialog(
          context: context,
          tone: AppDialogTone.success,
          title: l10n.messageSuccessTitle,
          message: msg,
          primaryLabel: l10n.actionOk,
        ).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.forgotPasswordTitle),
      ),
      builder: (context, layout) => ConstrainedContent(
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.forgotPasswordMessage,
                  style: context.textTheme.bodyMedium,
                ),
                AppSpacing.gapXl,
                AppTextField(
                  controller: _emailController,
                  label: l10n.forgotPasswordFieldLabel,
                  hint: l10n.forgotPasswordFieldHint,
                  glyph: AppGlyphs.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => isValidEmail(value?.trim() ?? '')
                      ? null
                      : l10n.emailInvalid,
                  onFieldSubmitted: (_) => _submit(),
                ),
                AppSpacing.gapXl,
                AppButton(
                  label: l10n.actionSubmit,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
