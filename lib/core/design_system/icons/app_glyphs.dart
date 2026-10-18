import 'package:flutter/foundation.dart';

/// What fills a part of a glyph.
enum GlyphFill {
  /// Nothing: a line.
  none,

  /// The soft tint inside the icon.
  tint,

  /// The surface behind the icon, cutting a shape out of the tint, like a
  /// house's door.
  cut,

  /// The icon's own colour, for solid shapes.
  ink,
}

/// One shape of a glyph: an SVG element on the 24-unit grid, and what fills
/// it.
@immutable
class GlyphPart {
  const GlyphPart(this.element, {this.fill = GlyphFill.none});

  /// The SVG element, such as `<path d="..."/>`, without colours.
  final String element;
  final GlyphFill fill;
}

/// An icon of the design: lines in the icon's colour over soft tinted
/// fills, drawn on a 24-unit grid. A [strokeWidth] of zero draws its shapes
/// solid, without lines.
@immutable
class AppGlyph {
  const AppGlyph(this.parts, {this.strokeWidth = 1.8});

  final List<GlyphPart> parts;
  final double strokeWidth;
}

/// The design's icons, drawn with its paths, fills and stroke widths.
abstract final class AppGlyphs {
  /// Home, in the navigation bar.
  static const home = AppGlyph([
    GlyphPart(
      '<path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart(
      '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/>',
      fill: GlyphFill.cut,
    ),
  ], strokeWidth: 1.9);

  /// A train seen head on, on its rails: tracking.
  static const train = AppGlyph([
    GlyphPart(
      '<rect x="5" y="2.5" width="14" height="15.5" rx="4.5"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart(
      '<rect x="7.5" y="5.5" width="9" height="5" rx="1.5"/>',
      fill: GlyphFill.cut,
    ),
    GlyphPart('<circle cx="9" cy="14.25" r="1.1"/>', fill: GlyphFill.ink),
    GlyphPart('<circle cx="15" cy="14.25" r="1.1"/>', fill: GlyphFill.ink),
    GlyphPart('<path d="M8.5 18 6.5 21.5M15.5 18l2 3.5M7.5 20h9"/>'),
  ]);

  /// Alerts.
  static const bell = AppGlyph([
    GlyphPart(
      '<path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<path d="M10.268 21a2 2 0 0 0 3.464 0"/>'),
  ]);

  /// Attendance, in a navigation bar.
  static const navAttendance = AppGlyph([
    GlyphPart(
      '<rect width="18" height="18" x="3" y="4" rx="2"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<path d="M8 2v4"/>'),
    GlyphPart('<path d="M16 2v4"/>'),
    GlyphPart('<path d="M3 10h18"/>'),
    GlyphPart('<path d="m9 16 2 2 4-4"/>'),
  ]);

  /// Leave, in a navigation bar: an application form.
  static const navLeave = AppGlyph([
    GlyphPart(
      '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<path d="M14 2v4a2 2 0 0 0 2 2h4"/>'),
    GlyphPart('<path d="M10 9H8"/>'),
    GlyphPart('<path d="M16 13H8"/>'),
    GlyphPart('<path d="M16 17H8"/>'),
  ]);

  /// The team, in a navigation bar.
  static const navTeam = AppGlyph([
    GlyphPart(
      '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<circle cx="9" cy="7" r="4"/>', fill: GlyphFill.tint),
    GlyphPart('<path d="M22 21v-2a4 4 0 0 0-3-3.87"/>'),
    GlyphPart('<path d="M16 3.13a4 4 0 0 1 0 7.75"/>'),
  ]);

  /// The profile.
  static const profile = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>', fill: GlyphFill.tint),
    GlyphPart('<circle cx="12" cy="10" r="3"/>', fill: GlyphFill.cut),
    GlyphPart('<path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662"/>'),
  ]);

  /// Face check-in.
  static const scanFace = AppGlyph([
    // The scan's corners, square on the grid, the lower right one giving
    // way to the check.
    GlyphPart('<path d="M2 7V4.5A2.5 2.5 0 0 1 4.5 2H7"/>'),
    GlyphPart('<path d="M17 2h2.5A2.5 2.5 0 0 1 22 4.5V7"/>'),
    GlyphPart('<path d="M2 17v2.5A2.5 2.5 0 0 0 4.5 22H7"/>'),
    // A head and shoulders in the middle, the face marked with points as
    // it is read.
    GlyphPart(
      '<path d="M6.6 20.2c1.5-.7 2.9-1 3.7-1.7v-1.6c-1.9-1.1-3.1-3.3-3.1-6 0-3.2 2.1-5.4 4.8-5.4s4.8 2.2 4.8 5.4c0 2.7-1.2 4.9-3.1 6v1.6c.3.3.7.5 1.2.7"/>',
    ),
    GlyphPart(
      '<path d="M9.6 9.2h.01M12.4 8.3h.01M14.3 10.4h.01M10.6 11.6h.01M13.2 12.7h.01M11.1 14.3h.01"/>',
    ),
    // Checked.
    GlyphPart('<circle cx="19" cy="19" r="3.4"/>'),
    GlyphPart('<path d="m17.5 19.1 1.1 1.1 2.3-2.4"/>'),
  ], strokeWidth: 1.6);

  /// Opens a module.
  static const arrowUpRight = AppGlyph([
    GlyphPart('<path d="M7 17 17 7"/>'),
    GlyphPart('<path d="M8 7h9v9"/>'),
  ], strokeWidth: 2.4);

  /// Goes on.
  static const arrowRight = AppGlyph([
    GlyphPart('<path d="M5 12h14"/>'),
    GlyphPart('<path d="m12 5 7 7-7 7"/>'),
  ], strokeWidth: 2.4);

  /// Goes back.
  static const arrowLeft = AppGlyph([
    GlyphPart('<path d="m12 19-7-7 7-7"/>'),
    GlyphPart('<path d="M19 12H5"/>'),
  ], strokeWidth: 2.4);

  /// Up, as a train direction.
  static const arrowUp = AppGlyph([
    GlyphPart('<path d="M12 19V5"/>'),
    GlyphPart('<path d="m5 12 7-7 7 7"/>'),
  ], strokeWidth: 2.6);

  /// Down, as a train direction.
  static const arrowDown = AppGlyph([
    GlyphPart('<path d="M12 5v14"/>'),
    GlyphPart('<path d="m19 12-7 7-7-7"/>'),
  ], strokeWidth: 2.6);

  /// Both directions.
  static const arrowUpDown = AppGlyph([
    GlyphPart('<path d="m3 16 4 4 4-4"/>'),
    GlyphPart('<path d="M7 20V4"/>'),
    GlyphPart('<path d="m21 8-4-4-4 4"/>'),
    GlyphPart('<path d="M17 4v16"/>'),
  ], strokeWidth: 2.2);

  /// Back.
  static const chevronLeft = AppGlyph([
    GlyphPart('<path d="m15 18-6-6 6-6"/>'),
  ], strokeWidth: 2.2);

  /// Opens a row.
  static const chevronRight = AppGlyph([
    GlyphPart('<path d="m9 18 6-6-6-6"/>'),
  ], strokeWidth: 2.4);

  /// Opens a choice.
  static const chevronDown = AppGlyph([
    GlyphPart('<path d="m6 9 6 6 6-6"/>'),
  ], strokeWidth: 2.4);

  /// Closes a choice.
  static const chevronUp = AppGlyph([
    GlyphPart('<path d="m18 15-6-6-6 6"/>'),
  ], strokeWidth: 2.2);

  /// Full screen.
  static const expand = AppGlyph([
    GlyphPart('<path d="m21 21-6-6m6 6v-4.8m0 4.8h-4.8"/>'),
    GlyphPart('<path d="M3 16.2V21m0 0h4.8M3 21l6-6"/>'),
    GlyphPart('<path d="M21 7.8V3m0 0h-4.8M21 3l-6 6"/>'),
    GlyphPart('<path d="M3 7.8V3m0 0h4.8M3 3l6 6"/>'),
  ], strokeWidth: 2.4);

  /// Done, chosen or approved.
  static const check = AppGlyph([
    GlyphPart('<path d="M20 6 9 17l-5-5"/>'),
  ], strokeWidth: 3);

  /// Closes or removes.
  static const close = AppGlyph([
    GlyphPart('<path d="M18 6 6 18"/>'),
    GlyphPart('<path d="m6 6 12 12"/>'),
  ], strokeWidth: 2.2);

  /// Adds something new.
  static const plus = AppGlyph([
    GlyphPart('<path d="M5 12h14"/>'),
    GlyphPart('<path d="M12 5v14"/>'),
  ], strokeWidth: 2.4);

  /// Search.
  static const search = AppGlyph([
    GlyphPart('<circle cx="11" cy="11" r="8"/>'),
    GlyphPart('<path d="m21 21-4.3-4.3"/>'),
  ], strokeWidth: 2.2);

  /// Share.
  static const share = AppGlyph([
    GlyphPart('<circle cx="18" cy="5" r="3"/>'),
    GlyphPart('<circle cx="6" cy="12" r="3"/>'),
    GlyphPart('<circle cx="18" cy="19" r="3"/>'),
    GlyphPart('<line x1="8.59" x2="15.42" y1="13.51" y2="17.49"/>'),
    GlyphPart('<line x1="15.41" x2="8.59" y1="6.51" y2="10.49"/>'),
  ], strokeWidth: 2);

  /// Reload.
  static const refresh = AppGlyph([
    GlyphPart('<path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8"/>'),
    GlyphPart('<path d="M21 3v5h-5"/>'),
  ], strokeWidth: 2.4);

  /// A new version to get.
  /// Sends something away, as a report submitted.
  static const upload = AppGlyph([
    GlyphPart('<path d="M12 3v12"/>'),
    GlyphPart('<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>'),
    GlyphPart('<path d="m17 8-5-5-5 5"/>'),
  ], strokeWidth: 2.2);

  static const download = AppGlyph([
    GlyphPart('<path d="M12 15V3"/>'),
    GlyphPart('<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>'),
    GlyphPart('<path d="m7 10 5 5 5-5"/>'),
  ], strokeWidth: 2.2);

  /// Signs out or leaves the app.
  static const logOut = AppGlyph([
    GlyphPart('<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>'),
    GlyphPart('<polyline points="16 17 21 12 16 7"/>'),
    GlyphPart('<line x1="21" x2="9" y1="12" y2="12"/>'),
  ], strokeWidth: 2.2);

  /// Deletes a digit.
  static const backspace = AppGlyph([
    GlyphPart(
      '<path d="M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z"/>',
    ),
    GlyphPart('<path d="m12 9 6 6"/>'),
    GlyphPart('<path d="m18 9-6 6"/>'),
  ]);

  /// Shows a password.
  static const eye = AppGlyph([
    GlyphPart(
      '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/>',
    ),
    GlyphPart('<circle cx="12" cy="12" r="3"/>'),
  ], strokeWidth: 1.9);

  /// Hides a password.
  static const eyeOff = AppGlyph([
    GlyphPart(
      '<path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/>',
    ),
    GlyphPart('<path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/>'),
    GlyphPart(
      '<path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/>',
    ),
    GlyphPart('<path d="m2 2 20 20"/>'),
  ], strokeWidth: 1.9);

  /// Something needs fixing.
  static const circleAlert = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M12 8v4"/>'),
    GlyphPart('<path d="M12 16h.01"/>'),
  ], strokeWidth: 2);

  /// A question.
  static const circleHelp = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>'),
    GlyphPart('<path d="M12 17h.01"/>'),
  ], strokeWidth: 2);

  /// Minor.
  static const circleMinus = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M8 12h8"/>'),
  ], strokeWidth: 2.4);

  /// News.
  static const info = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M12 16v-4"/>'),
    GlyphPart('<path d="M12 8h.01"/>'),
  ], strokeWidth: 2);

  /// A warning.
  static const triangleAlert = AppGlyph([
    GlyphPart(
      '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>',
    ),
    GlyphPart('<path d="M12 9v4"/>'),
    GlyphPart('<path d="M12 17h.01"/>'),
  ], strokeWidth: 2.2);

  /// Waiting.
  static const hourglass = AppGlyph([
    GlyphPart('<path d="M5 22h14"/>'),
    GlyphPart('<path d="M5 2h14"/>'),
    GlyphPart(
      '<path d="M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"/>',
    ),
    GlyphPart(
      '<path d="M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"/>',
    ),
  ], strokeWidth: 2.8);

  /// Moving: speed.
  static const gauge = AppGlyph([
    GlyphPart('<path d="m12 14 4-4"/>'),
    GlyphPart('<path d="M3.34 19a10 10 0 1 1 17.32 0"/>'),
  ], strokeWidth: 2.6);

  /// Sign in to PROMISE.
  static const shieldCheck = AppGlyph([
    GlyphPart(
      '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
    ),
    GlyphPart('<path d="m9 12 2 2 4-4"/>'),
  ], strokeWidth: 2.1);

  /// Verified.
  static const badgeCheck = AppGlyph([
    GlyphPart(
      '<path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"/>',
    ),
    GlyphPart('<path d="m9 12 2 2 4-4"/>'),
  ], strokeWidth: 2);

  /// A person.
  static const user = AppGlyph([
    GlyphPart('<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>'),
    GlyphPart('<circle cx="12" cy="7" r="4"/>'),
  ], strokeWidth: 1.9);

  /// Signal bars: a mobile network.
  static const signal = AppGlyph([
    GlyphPart('<path d="M2 20h.01"/>'),
    GlyphPart('<path d="M7 20v-4"/>'),
    GlyphPart('<path d="M12 20v-8"/>'),
    GlyphPart('<path d="M17 20V8"/>'),
    GlyphPart('<path d="M22 4v16"/>'),
  ], strokeWidth: 2.2);

  /// People: a team.
  static const users = AppGlyph([
    GlyphPart('<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>'),
    GlyphPart('<circle cx="9" cy="7" r="4"/>'),
    GlyphPart('<path d="M22 21v-2a4 4 0 0 0-3-3.87"/>'),
    GlyphPart('<path d="M16 3.13a4 4 0 0 1 0 7.75"/>'),
  ], strokeWidth: 2);

  /// A job: a designation.
  static const briefcase = AppGlyph([
    GlyphPart('<path d="M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>'),
    GlyphPart('<rect width="20" height="14" x="2" y="6" rx="2"/>'),
  ], strokeWidth: 1.9);

  /// Layers: a division within a department.
  static const layers = AppGlyph([
    GlyphPart(
      '<path d="M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/>',
    ),
    GlyphPart('<path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/>'),
    GlyphPart('<path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>'),
  ], strokeWidth: 1.9);

  /// A person approved: a team.
  static const userCheck = AppGlyph([
    GlyphPart('<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>'),
    GlyphPart('<circle cx="9" cy="7" r="4"/>'),
    GlyphPart('<polyline points="16 11 18 13 22 9"/>'),
  ], strokeWidth: 2);

  /// An employee ID.
  static const idCard = AppGlyph([
    GlyphPart('<path d="M16 10h2"/>'),
    GlyphPart('<path d="M16 14h2"/>'),
    GlyphPart('<path d="M6.17 15a3 3 0 0 1 5.66 0"/>'),
    GlyphPart('<circle cx="9" cy="11" r="2"/>'),
    GlyphPart('<rect x="2" y="5" width="20" height="14" rx="2"/>'),
  ], strokeWidth: 2);

  /// A password.
  static const lock = AppGlyph([
    GlyphPart('<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/>'),
    GlyphPart('<path d="M7 11V7a5 5 0 0 1 10 0v4"/>'),
  ], strokeWidth: 2);

  /// Fingerprint sign-in.
  static const fingerprint = AppGlyph([
    GlyphPart('<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/>'),
    GlyphPart('<path d="M14 13.12c0 2.38 0 6.38-1 8.88"/>'),
    GlyphPart('<path d="M17.29 21.02c.12-.6.43-2.3.5-3.02"/>'),
    GlyphPart('<path d="M2 12a10 10 0 0 1 18-6"/>'),
    GlyphPart('<path d="M2 16h.01"/>'),
    GlyphPart('<path d="M21.8 16c.2-2 .131-5.354 0-6"/>'),
    GlyphPart('<path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/>'),
    GlyphPart('<path d="M8.65 22c.21-.66.45-1.32.57-2"/>'),
    GlyphPart('<path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>'),
  ], strokeWidth: 2);

  /// An email address.
  static const mail = AppGlyph([
    GlyphPart('<rect width="20" height="16" x="2" y="4" rx="2"/>'),
    GlyphPart('<path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>'),
  ], strokeWidth: 2);

  /// A mobile phone.
  static const smartphone = AppGlyph([
    GlyphPart('<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/>'),
    GlyphPart('<path d="M12 18h.01"/>'),
  ], strokeWidth: 1.9);

  /// A call.
  static const phone = AppGlyph([
    GlyphPart(
      '<path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/>',
    ),
  ], strokeWidth: 2.2);

  /// Language.
  static const globe = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/>'),
    GlyphPart('<path d="M2 12h20"/>'),
  ], strokeWidth: 1.9);

  /// A photo.
  static const camera = AppGlyph([
    GlyphPart(
      '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/>',
    ),
    GlyphPart('<circle cx="12" cy="13" r="3"/>'),
  ], strokeWidth: 2);

  /// A camera that doesn't work.
  static const cameraOff = AppGlyph([
    GlyphPart('<line x1="2" x2="22" y1="2" y2="22"/>'),
    GlyphPart('<path d="M7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16"/>'),
    GlyphPart('<path d="M9.5 4h5L17 7h3a2 2 0 0 1 2 2v7.5"/>'),
    GlyphPart('<path d="M14.121 15.121A3 3 0 1 1 9.88 10.88"/>'),
  ], strokeWidth: 2);

  /// Bold text.
  static const bold = AppGlyph([
    GlyphPart(
      '<path d="M6 12h9a4 4 0 0 1 0 8H7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h7a4 4 0 0 1 0 8"/>',
    ),
  ], strokeWidth: 2.4);

  /// A small "a" beside a large "A": the size of the text and screen.
  static const textSize = AppGlyph([
    GlyphPart('<path d="m15 16 2.536-7.328a1.02 1.02 1 0 1 1.928 0L22 16"/>'),
    GlyphPart('<path d="M15.697 14h5.606"/>'),
    GlyphPart('<path d="m2 16 4.039-9.69a.5.5 0 0 1 .923 0L11 16"/>'),
    GlyphPart('<path d="M3.304 13h6.392"/>'),
  ], strokeWidth: 2);

  /// A photo, as from the gallery.
  static const image = AppGlyph([
    GlyphPart('<rect width="18" height="18" x="3" y="3" rx="2"/>'),
    GlyphPart('<circle cx="9" cy="9" r="2"/>'),
    GlyphPart('<path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>'),
  ], strokeWidth: 2);

  /// A smiling face, as an avatar.
  static const smile = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M8 14s1.5 2 4 2 4-2 4-2"/>'),
    GlyphPart('<path d="M9 9h.01M15 9h.01"/>'),
  ], strokeWidth: 2);

  /// Animals and nature.
  static const paw = AppGlyph([
    GlyphPart('<circle cx="11" cy="4" r="2"/>'),
    GlyphPart('<circle cx="18" cy="8" r="2"/>'),
    GlyphPart('<circle cx="20" cy="16" r="2"/>'),
    GlyphPart(
      '<path d="M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z"/>',
      fill: GlyphFill.tint,
    ),
  ], strokeWidth: 2);

  /// Food and drink.
  static const cup = AppGlyph([
    GlyphPart('<path d="M10 2v2M14 2v2M6 2v2"/>'),
    GlyphPart(
      '<path d="M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1"/>',
      fill: GlyphFill.tint,
    ),
  ], strokeWidth: 2);

  /// Activities.
  static const trophy = AppGlyph([
    GlyphPart(
      '<path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6M18 9h1.5a2.5 2.5 0 0 0 0-5H18M4 22h16"/>',
    ),
    GlyphPart(
      '<path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/>',
    ),
    GlyphPart('<path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/>', fill: GlyphFill.tint),
  ], strokeWidth: 2);

  /// Travel and places.
  static const car = AppGlyph([
    GlyphPart(
      '<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<circle cx="7" cy="17" r="2"/>'),
    GlyphPart('<path d="M9 17h6"/>'),
    GlyphPart('<circle cx="17" cy="17" r="2"/>'),
  ], strokeWidth: 2);

  /// Objects.
  static const lightbulb = AppGlyph([
    GlyphPart(
      '<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<path d="M9 18h6M10 22h4"/>'),
  ], strokeWidth: 2);

  /// Symbols.
  static const heart = AppGlyph([
    GlyphPart(
      '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
      fill: GlyphFill.tint,
    ),
  ], strokeWidth: 2);

  /// Flags.
  static const flag = AppGlyph([
    GlyphPart(
      '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/>',
      fill: GlyphFill.tint,
    ),
    GlyphPart('<path d="M4 22v-7"/>'),
  ], strokeWidth: 2);

  /// Removes something.
  static const trash = AppGlyph([
    GlyphPart('<path d="M3 6h18"/>'),
    GlyphPart('<path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/>'),
    GlyphPart('<path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>'),
    GlyphPart('<path d="M10 11v6M14 11v6"/>'),
  ], strokeWidth: 2);

  /// A date.
  static const calendar = AppGlyph([
    GlyphPart('<path d="M8 2v4"/>'),
    GlyphPart('<path d="M16 2v4"/>'),
    GlyphPart('<rect width="18" height="18" x="3" y="4" rx="2"/>'),
    GlyphPart('<path d="M3 10h18"/>'),
  ], strokeWidth: 2);

  /// Leave approved or applied.
  static const calendarCheck = AppGlyph([
    GlyphPart('<path d="M8 2v4"/>'),
    GlyphPart('<path d="M16 2v4"/>'),
    GlyphPart('<rect width="18" height="18" x="3" y="4" rx="2"/>'),
    GlyphPart('<path d="M3 10h18"/>'),
    GlyphPart('<path d="m9 16 2 2 4-4"/>'),
  ], strokeWidth: 1.9);

  /// A time.
  static const clock = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="10"/>'),
    GlyphPart('<path d="M12 6v6l4 2"/>'),
  ], strokeWidth: 2);

  /// What happened before.
  static const history = AppGlyph([
    GlyphPart('<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>'),
    GlyphPart('<path d="M3 3v5h5"/>'),
    GlyphPart('<path d="M12 7v5l4 2"/>'),
  ], strokeWidth: 2.2);

  /// A checklist: an inspection.
  static const clipboardList = AppGlyph([
    GlyphPart('<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/>'),
    GlyphPart(
      '<path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>',
    ),
    GlyphPart('<path d="M12 11h4"/>'),
    GlyphPart('<path d="M12 16h4"/>'),
    GlyphPart('<path d="M8 11h.01"/>'),
    GlyphPart('<path d="M8 16h.01"/>'),
  ], strokeWidth: 1.9);

  /// A report being written.
  static const fileEdit = AppGlyph([
    GlyphPart(
      '<path d="M12.5 22H18a2 2 0 0 0 2-2V7l-5-5H6a2 2 0 0 0-2 2v9.5"/>',
    ),
    GlyphPart('<path d="M14 2v4a2 2 0 0 0 2 2h4"/>'),
    GlyphPart(
      '<path d="M13.378 15.626a1 1 0 1 0-3.004-3.004l-5.01 5.012a2 2 0 0 0-.506.854l-.837 2.87a.5.5 0 0 0 .62.62l2.87-.837a2 2 0 0 0 .854-.506z"/>',
    ),
  ], strokeWidth: 1.9);

  /// A list.
  static const list = AppGlyph([
    GlyphPart('<path d="M3 12h.01"/>'),
    GlyphPart('<path d="M3 18h.01"/>'),
    GlyphPart('<path d="M3 6h.01"/>'),
    GlyphPart('<path d="M8 12h13"/>'),
    GlyphPart('<path d="M8 18h13"/>'),
    GlyphPart('<path d="M8 6h13"/>'),
  ], strokeWidth: 2.4);

  /// A number.
  static const hash = AppGlyph([
    GlyphPart('<line x1="4" x2="20" y1="9" y2="9"/>'),
    GlyphPart('<line x1="4" x2="20" y1="15" y2="15"/>'),
    GlyphPart('<line x1="10" x2="8" y1="3" y2="21"/>'),
    GlyphPart('<line x1="16" x2="14" y1="3" y2="21"/>'),
  ], strokeWidth: 2.2);

  /// Fewer.
  static const rectMinus = AppGlyph([
    GlyphPart('<rect width="18" height="14" x="3" y="5" rx="3"/>'),
    GlyphPart('<path d="M8 12h8"/>'),
  ], strokeWidth: 2);

  /// A map.
  static const map = AppGlyph([
    GlyphPart(
      '<path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/>',
    ),
    GlyphPart('<path d="M15 5.764v15"/>'),
    GlyphPart('<path d="M9 3.236v15"/>'),
  ], strokeWidth: 2.2);

  /// A place.
  static const mapPin = AppGlyph([
    GlyphPart(
      '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/>',
    ),
    GlyphPart('<circle cx="12" cy="10" r="3"/>'),
  ], strokeWidth: 2.2);

  /// A location that can't be trusted.
  static const mapPinX = AppGlyph([
    GlyphPart(
      '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/>',
    ),
    GlyphPart('<path d="m9.5 7.5 5 5"/>'),
    GlyphPart('<path d="m14.5 7.5-5 5"/>'),
  ], strokeWidth: 2.2);

  /// A route.
  static const route = AppGlyph([
    GlyphPart('<circle cx="6" cy="19" r="3"/>'),
    GlyphPart(
      '<path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/>',
    ),
    GlyphPart('<circle cx="18" cy="5" r="3"/>'),
  ], strokeWidth: 2.4);

  /// Find me.
  static const locate = AppGlyph([
    GlyphPart('<line x1="2" x2="5" y1="12" y2="12"/>'),
    GlyphPart('<line x1="19" x2="22" y1="12" y2="12"/>'),
    GlyphPart('<line x1="12" x2="12" y1="2" y2="5"/>'),
    GlyphPart('<line x1="12" x2="12" y1="19" y2="22"/>'),
    GlyphPart('<circle cx="12" cy="12" r="7"/>'),
  ], strokeWidth: 2);

  /// Instant locomotive positioning.
  static const locateFixed = AppGlyph([
    GlyphPart('<circle cx="12" cy="12" r="3"/>', fill: GlyphFill.ink),
    GlyphPart('<circle cx="12" cy="12" r="7"/>'),
    GlyphPart('<path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>'),
  ], strokeWidth: 2.2);

  /// Live by satellite.
  static const satellite = AppGlyph([
    GlyphPart('<path d="M13 7 9 3 5 7l4 4"/>'),
    GlyphPart('<path d="m17 11 4 4-4 4-4-4"/>'),
    GlyphPart('<path d="m8 12 4 4 6-6-4-4Z"/>'),
    GlyphPart('<path d="m16 8 3-3"/>'),
    GlyphPart('<path d="M9 21a6 6 0 0 0-6-6"/>'),
  ], strokeWidth: 2.2);

  /// A GPS device.
  static const radio = AppGlyph([
    GlyphPart('<path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9"/>'),
    GlyphPart('<path d="M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5"/>'),
    GlyphPart('<circle cx="12" cy="12" r="2"/>'),
    GlyphPart('<path d="M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5"/>'),
    GlyphPart('<path d="M19.1 4.9C23 8.8 23 15.1 19.1 19"/>'),
  ], strokeWidth: 2.2);

  /// A mobile network.
  static const radioTower = AppGlyph([
    GlyphPart('<path d="M4.9 16.1C1 12.2 1 5.8 4.9 1.9"/>'),
    GlyphPart('<path d="M7.8 4.7a6.14 6.14 0 0 0-.8 7.5"/>'),
    GlyphPart('<circle cx="12" cy="9" r="2"/>'),
    GlyphPart('<path d="M16.2 4.8c2 2 2.26 5.11.8 7.47"/>'),
    GlyphPart('<path d="M19.1 1.9a9.96 9.96 0 0 1 0 14.1"/>'),
    GlyphPart('<path d="M9.5 18h5"/>'),
    GlyphPart('<path d="m8 22 4-11 4 11"/>'),
  ], strokeWidth: 2);

  /// Online.
  static const wifi = AppGlyph([
    GlyphPart('<path d="M12 20h.01"/>'),
    GlyphPart('<path d="M2 8.82a15 15 0 0 1 20 0"/>'),
    GlyphPart('<path d="M5 12.859a10 10 0 0 1 14 0"/>'),
    GlyphPart('<path d="M8.5 16.429a5 5 0 0 1 7 0"/>'),
  ], strokeWidth: 2);

  /// Offline.
  static const wifiOff = AppGlyph([
    GlyphPart('<path d="M12 20h.01"/>'),
    GlyphPart('<path d="M8.5 16.429a5 5 0 0 1 7 0"/>'),
    GlyphPart('<path d="M5 12.859a10 10 0 0 1 5.17-2.69"/>'),
    GlyphPart('<path d="M19 12.859a10 10 0 0 0-2.007-1.523"/>'),
    GlyphPart('<path d="M2 8.82a15 15 0 0 1 4.177-2.643"/>'),
    GlyphPart('<path d="M22 8.82a15 15 0 0 0-11.288-3.764"/>'),
    GlyphPart('<path d="m2 2 20 20"/>'),
  ], strokeWidth: 2);

  /// An office.
  static const building = AppGlyph([
    GlyphPart('<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/>'),
    GlyphPart('<path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2"/>'),
    GlyphPart('<path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2"/>'),
    GlyphPart('<path d="M10 6h4"/>'),
    GlyphPart('<path d="M10 10h4"/>'),
    GlyphPart('<path d="M10 14h4"/>'),
    GlyphPart('<path d="M10 18h4"/>'),
  ], strokeWidth: 1.9);

  /// A station.
  static const station = AppGlyph([
    GlyphPart('<polygon points="12 2 20 7 4 7"/>'),
    GlyphPart('<line x1="3" x2="21" y1="22" y2="22"/>'),
    GlyphPart('<line x1="6" x2="6" y1="18" y2="11"/>'),
    GlyphPart('<line x1="10" x2="10" y1="18" y2="11"/>'),
    GlyphPart('<line x1="14" x2="14" y1="18" y2="11"/>'),
    GlyphPart('<line x1="18" x2="18" y1="18" y2="11"/>'),
  ]);

  /// A motor trolley.
  static const truck = AppGlyph([
    GlyphPart(
      '<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/>',
    ),
    GlyphPart('<path d="M15 18H9"/>'),
    GlyphPart(
      '<path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/>',
    ),
    GlyphPart('<circle cx="17" cy="18" r="2"/>'),
    GlyphPart('<circle cx="7" cy="18" r="2"/>'),
  ]);

  /// A locomotive check.
  static const wrench = AppGlyph([
    GlyphPart(
      '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
    ),
  ]);

  /// Electrical.
  static const zap = AppGlyph([
    GlyphPart(
      '<path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>',
    ),
  ]);

  /// An accident.
  static const siren = AppGlyph([
    GlyphPart('<path d="M7 18v-6a5 5 0 1 1 10 0v6"/>'),
    GlyphPart(
      '<path d="M5 21a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-1a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2z"/>',
    ),
    GlyphPart('<path d="M21 12h1"/>'),
    GlyphPart('<path d="M18.5 4.5 18 5"/>'),
    GlyphPart('<path d="M2 12h1"/>'),
    GlyphPart('<path d="M12 2v1"/>'),
    GlyphPart('<path d="m4.929 4.929.707.707"/>'),
    GlyphPart('<path d="M12 12v6"/>'),
  ], strokeWidth: 1.9);

  /// All, as a filter.
  static const gridFilled = AppGlyph([
    GlyphPart(
      '<path d="M4 8h4V4H4v4zm6 12h4v-4h-4v4zm-6 0h4v-4H4v4zm0-6h4v-4H4v4zm6 0h4v-4h-4v4zm6-10v4h4V4h-4zm-6 4h4V4h-4v4zm6 6h4v-4h-4v4zm0 6h4v-4h-4v4z"/>',
      fill: GlyphFill.ink,
    ),
  ], strokeWidth: 0);

  /// Stopped.
  static const pauseFilled = AppGlyph([
    GlyphPart(
      '<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14H9V8h2v8zm4 0h-2V8h2v8z"/>',
      fill: GlyphFill.ink,
    ),
  ], strokeWidth: 0);

  /// A train, solid.
  static const trainFilled = AppGlyph([
    GlyphPart(
      '<path d="M12 2c-4 0-8 .5-8 4v9.5C4 17.43 5.57 19 7.5 19L6 20.5v.5h2.23l2-2H14l2 2h2v-.5L16.5 19c1.93 0 3.5-1.57 3.5-3.5V6c0-3.5-3.58-4-8-4zM7.5 17c-.83 0-1.5-.67-1.5-1.5S6.67 14 7.5 14s1.5.67 1.5 1.5S8.33 17 7.5 17zm3.5-7H6V6h5v4zm2 0V6h5v4h-5zm3.5 7c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/>',
      fill: GlyphFill.ink,
    ),
  ], strokeWidth: 0);

  /// Heading.
  static const navigationFilled = AppGlyph([
    GlyphPart(
      '<path d="M12 2 4.5 20.29l.71.71L12 18l6.79 3 .71-.71z"/>',
      fill: GlyphFill.ink,
    ),
  ], strokeWidth: 0);

  /// A place, solid.
  static const mapPinFilled = AppGlyph([
    GlyphPart(
      '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>',
      fill: GlyphFill.ink,
    ),
  ], strokeWidth: 0);

  /// The next station.
  static const nearMeFilled = AppGlyph([
    GlyphPart(
      '<path d="M21 3 3 10.53v.98l6.84 2.65L12.48 21h.98L21 3z"/>',
      fill: GlyphFill.ink,
    ),
  ], strokeWidth: 0);
}
