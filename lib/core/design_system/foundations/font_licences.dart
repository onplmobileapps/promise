import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';

/// Adds the bundled fonts' SIL Open Font Licences to the app's licence page.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, path) in [
      (AppFonts.text, AppAssets.interLicence),
      (AppFonts.display, AppAssets.outfitLicence),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(path));
    }
  });
}
