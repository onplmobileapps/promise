import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/utils/validators.dart';
import 'package:railway_hrms/modules/auth/screens/tracking_identity_view.dart';
import 'package:railway_hrms/modules/auth/widgets/auth_form_header.dart';

// The network operator isn't asked for for now; see the field below.
// import 'package:railway_hrms/modules/auth/data/models/network_operator.dart';
// import 'package:railway_hrms/modules/auth/widgets/network_operator_logo.dart';

/// Train tracking sign-in: the traveller enters their mobile number, 03 and
/// nine more digits, and goes on to scan their CNIC.
class MobileSignInForm extends StatefulWidget {
  const MobileSignInForm({super.key});

  /// Digits in a Pakistani mobile number written with its leading zero.
  static const mobileNumberLength = pakistaniMobileLength;

  @override
  State<MobileSignInForm> createState() => _MobileSignInFormState();
}

class _MobileSignInFormState extends State<MobileSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  /// Continue has been pressed: a number left empty or short is now an
  /// error too, not only one that starts wrong.
  bool _submitted = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    _submitted = true;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TrackingIdentityView(phoneNumber: _phoneController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormHeader(
            title: l10n.loginTitle,
            subtitle: l10n.loginTrackingSubtitle,
          ),
          AppSpacing.gapXl,
          // The network operator isn't asked for for now.
          // AppSelectField<NetworkOperator>(
          //   label: l10n.networkOperatorLabel,
          //   hint: l10n.networkOperatorHint,
          //   glyph: AppGlyphs.signal,
          //   options: NetworkOperator.all,
          //   optionLabel: (operator) => operator.name,
          //   gridOptions: true,
          //   optionLeading: (context, operator, size) =>
          //       NetworkOperatorLogo(operator: operator, size: size),
          //   validator: (value) =>
          //       value == null ? l10n.networkOperatorRequired : null,
          // ),
          // AppSpacing.gapMd,
          AppTextField(
            controller: _phoneController,
            label: l10n.mobileNumberLabel,
            hint: l10n.mobileNumberHint,
            glyph: AppGlyphs.smartphone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [
              const _LocalMobileFormatter(),
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                MobileSignInForm.mobileNumberLength,
              ),
            ],
            // A wrong start is said as it is typed; an empty or short number
            // once Continue is pressed, and then until it is put right.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => switch (mobileNumberProblem(value ?? '')) {
              null => null,
              MobileNumberProblem.prefix => l10n.mobileNumberStart,
              MobileNumberProblem.empty =>
                _submitted ? l10n.mobileNumberRequired : null,
              MobileNumberProblem.length =>
                _submitted ? l10n.mobileNumberLength : null,
            },
            onFieldSubmitted: (_) => _continue(),
          ),
          AppSpacing.gapXl,
          AppButton(
            label: l10n.actionContinue,
            trailingGlyph: AppGlyphs.arrowRight,
            onPressed: _continue,
          ),
        ],
      ),
    );
  }
}

/// A number pasted in international form, as +92 300 1234567 or
/// 0092 300 1234567, written as it is dialled at home: 03001234567.
class _LocalMobileFormatter extends TextInputFormatter {
  const _LocalMobileFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String local;
    if (digits.startsWith('0092') && digits.length >= 14) {
      local = digits.substring(4);
    } else if (digits.startsWith('92') && digits.length >= 12) {
      local = digits.substring(2);
    } else {
      return newValue;
    }
    final text = '0$local';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
