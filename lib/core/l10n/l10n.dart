import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/l10n/generated/app_localizations.dart';

export 'package:railway_hrms/core/l10n/generated/app_localizations.dart';

/// The app's strings for the current locale: `context.l10n.loginTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
