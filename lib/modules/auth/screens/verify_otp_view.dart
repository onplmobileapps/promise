import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/auth/controllers/otp_timer_controller.dart';
import 'package:railway_hrms/modules/auth/widgets/auth_scaffold.dart';

/// Checks the one-time code sent to a traveller's phone for train tracking
/// sign-in.
class VerifyOtpView extends StatefulWidget {
  const VerifyOtpView({
    super.key,
    required this.phoneNumber,
    this.codeLength = 6,
  });

  /// The number the code went to, as the user should read it.
  final String phoneNumber;
  final int codeLength;

  @override
  State<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  final _timer = OtpTimerController();

  @override
  void initState() {
    super.initState();
    _timer.start();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    _timer.dispose();
    super.dispose();
  }

  void _resend() => _timer.resend(() {
    _pinController.clear();
    _pinFocus.requestFocus();
  });

  // Mobile sign-in has no API yet, so the code goes nowhere.
  void _verify() {}

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;

    return AuthScaffold(
      appBar: AppBar(forceMaterialTransparency: true),
      footer: Text(
        l10n.copyrightNotice(DateTime.now().year),
        textAlign: TextAlign.center,
        style: text.bodySmall,
      ),
      builder: (context, layout) => ConstrainedContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!layout.isShort) ...[
              Center(
                child: AppLogo(
                  emblemWidth:
                      AppLogo.emblemWidthFor(
                        layout.constraints.biggest.shortestSide,
                      ) *
                      0.6,
                  showWordmark: false,
                ),
              ),
              AppSpacing.gapXxl,
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.otpTitle,
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                  AppSpacing.gapSm,
                  Text.rich(
                    TextSpan(
                      text: '${l10n.otpSubtitle(widget.codeLength)} ',
                      children: [
                        TextSpan(
                          text: widget.phoneNumber,
                          style: text.bodyMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: AppFonts.semiBold,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                  AppSpacing.gapXxl,
                  Semantics(
                    label: l10n.otpFieldLabel,
                    // The cells shrink to fit the narrowest phones.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppCodeField(
                        length: widget.codeLength,
                        controller: _pinController,
                        focusNode: _pinFocus,
                        onCompleted: (_) => _verify(),
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  ValueListenableBuilder<bool>(
                    valueListenable: _timer.canResend,
                    builder: (context, canResend, _) =>
                        ValueListenableBuilder<int>(
                          valueListenable: _timer.secondsRemaining,
                          builder: (context, seconds, _) => Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(l10n.otpNotReceived, style: text.bodyMedium),
                              AppButton(
                                variant: AppButtonVariant.text,
                                expand: false,
                                label: canResend
                                    ? l10n.otpResend
                                    : l10n.otpResendIn(seconds),
                                onPressed: canResend ? _resend : null,
                              ),
                            ],
                          ),
                        ),
                  ),
                  AppSpacing.gapMd,
                  AppButton(label: l10n.otpVerify, onPressed: _verify),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
