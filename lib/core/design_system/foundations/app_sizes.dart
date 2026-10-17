/// Fixed dimensions of controls and layout limits.
abstract final class AppSizes {
  /// The smallest tap target, per both platforms' guidelines.
  static const double minTapTarget = 48;

  static const double buttonHeight = 54;
  static const double buttonHeightCompact = 44;

  /// The three sizes of button: large for a screen's main action, medium
  /// for actions in cards and dialogs, small for actions in rows.
  static const double buttonLarge = 56;
  static const double buttonMedium = 48;
  static const double buttonSmall = 36;

  /// How far a raised key's edge shows below it, and how far it sinks when
  /// pressed.
  static const double keyEdge = 4;
  static const double keyEdgePressed = 1;

  static const double fieldHeight = 58;

  /// The ring around a focused or failing field.
  static const double fieldRing = 4;

  /// The ring around a focused key.
  static const double focusRing = 3;
  static const double segmentedHeight = 48;
  static const double sheetHandleWidth = 40;
  static const double sheetHandleHeight = 4;

  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  /// Stroke of the small spinners inside buttons and banners.
  static const double spinnerStroke = 2.4;

  /// A dialog's sphere badge, the halo around it, and the mark on it.
  static const double dialogBadge = 72;
  static const double dialogHalo = 10;
  static const double dialogMark = 34;
  static const double dialogMaxWidth = 400;

  /// The connection banner below the status bar: tall enough for its
  /// button to be a full tap target.
  static const double bannerHeight = minTapTarget;

  /// Forms and single-column content never grow wider than this, so lines
  /// stay readable on tablets.
  static const double formMaxWidth = 440;
  static const double contentMaxWidth = 720;

  /// The emblem's width as a share of the screen's shorter side, and its
  /// bounds.
  static const double emblemShare = 0.42;
  static const double emblemMin = 112;
  static const double emblemMax = 220;

  /// The wordmark's width relative to the emblem's.
  static const double wordmarkToEmblem = 1.3;

  /// The emblem image's aspect ratio (width / height).
  static const double emblemAspectRatio = 1472 / 1170;

  /// The wordmark image's aspect ratio (width / height).
  static const double wordmarkAspectRatio = 1600 / 240;

  /// The emblem medallion on the sign-in screen is drawn for a glass ring
  /// [medallionDesign] across and scaled from there. Its ring takes
  /// [medallionShare] of the screen's shorter side, within these bounds.
  static const double medallionDesign = 150;
  static const double medallionShare = 0.385;
  static const double medallionMin = 104;
  static const double medallionMax = 180;

  /// A raised dome is drawn [domeDesign] across, standing [domeEdge] high
  /// on its rim, with the middle [domeContent] of it kept for its content.
  static const double domeDesign = 112;
  static const double domeEdge = 6;
  static const double domeContent = 82 / 112;

  /// The wordmark under the medallion, as a share of the medallion.
  static const double wordmarkToMedallion = 1.2;

  /// The sign-in medallion's share of the screen's height at most, so the
  /// card and the footer fit under it.
  static const double loginMedallionHeightShare = 0.14;

  /// The mark beside an option: in a list of choices, and in the field
  /// once chosen.
  static const double optionLeading = 32;
  static const double optionLeadingCompact = 26;

  /// The square buttons and the avatar in a screen's header, and the ring
  /// around the avatar.
  static const double headerControl = 42;

  /// How wide the sample message of the text size preview grows.
  static const double textPreviewBubble = 300;

  /// The narrowest a zoomed display may lay out at, so the layouts fit.
  static const double zoomMinWidth = 330;

  /// The wheel of hours and minutes on a date and time sheet.
  static const double timeWheelHeight = 168;

  /// The jade key on an [AppFeatureCard], and its glyph.
  static const double featureKey = 48;
  static const double featureGlyph = 24;

  /// The phone drawn on a display size choice.
  static const double displayPreviewHeight = 132;
  static const double displayPreviewWidth = 72;

  /// A stepped slider: its knob, the height of its track, and the radius
  /// of the dot at each stop.
  static const double sliderKnob = 24;
  static const double sliderTrack = 8;
  static const double sliderTick = 2;

  /// The emoji picker: its height as a share of the screen, and each
  /// emoji's cell and size.
  static const double emojiSheetShare = 0.8;
  static const double emojiCell = 52;
  static const double emojiGlyph = 30;

  /// The emoji picker's avatar preview, and its colour swatches with the
  /// ring a picked one wears.
  static const double emojiPreview = 76;
  static const double emojiSwatch = 34;
  static const double emojiSwatchRing = 2;

  /// A profile photo is kept this wide at most, at this JPEG quality.
  static const double profilePhotoWidth = 720;
  static const int profilePhotoQuality = 85;

  /// The key on an avatar's corner, as a share of the avatar, and the ring
  /// round it.
  static const double avatarBadgeShare = 0.38;
  static const double avatarBadgeRing = 2.5;

  /// An emoji avatar's size, as a share of its circle.
  static const double avatarEmojiShare = 0.56;

  static const double avatarRing = 2;

  /// The emblem in the brand tile of a screen's header.
  static const double headerEmblem = 31;

  /// How far down the home screen its sage wash reaches.
  static const double homeWash = 360;

  /// How far down the home screen its pattern runs.
  static const double homePattern = 460;

  /// How strongly the blobs show behind sign-in and forms, and behind the
  /// alerts and the profile; and how far down their pattern runs.
  static const double blobIntensity = 0.5;
  static const double blobIntensityStrong = 0.85;
  static const double blobPattern = 360;

  /// The smallest a count badge gets.
  static const double badgeMinSize = 18;

  /// A module card: the 3D tile behind its icon, the icon, and the least
  /// height of the card.
  static const double moduleTile = 74;
  static const double moduleIcon = 64;

  /// The raised tile a field's icon, and its eye, sit on.
  static const double fieldIconTile = 32;
  static const double moduleCardMinHeight = 218;
  static const double moduleArrow = 28;

  /// The arrow inside a module card's arrow disc.
  static const double moduleArrowIcon = 15;

  /// Line icons in the navigation bar and a header's buttons.
  static const double glyphNav = 26;

  /// Line icons at the start of a settings row.
  static const double glyphRow = 19;

  /// The bottom navigation bar: its height above the system's inset, the
  /// pill behind the selected item, and the raised action in its middle,
  /// how far that stands above the bar and the ring of bar around it.
  static const double navBarHeight = 66;
  static const double navIndicatorWidth = 60;
  static const double navIndicatorHeight = 34;
  static const double navActionSize = 54;
  static const double navActionLift = 18;
  static const double navActionRing = 5;

  /// How much the bar's glass blurs the page under it, how much of the
  /// surface tints it, and how far an icon sinks while held.
  static const double navGlassBlur = 22;
  static const double navGlassOpacity = 0.72;
  static const double navPressScale = 0.86;

  /// The lens of liquid glass: how much it stretches along its way and
  /// flattens at full speed, how much it swells while moving or held, and
  /// how much it enlarges the icons it passes.
  static const double navLensStretch = 0.45;
  static const double navLensSquash = 0.12;
  static const double navLensSwell = 0.10;
  static const double navLensMagnify = 0.18;

  /// How far the drawn-out lens trails behind its middle, as a share of
  /// how much longer it is: its leading edge keeps up with the finger.
  static const double navLensLean = 0.35;

  /// How far an icon sinks while held where no drop of glass rises over
  /// it, as on Android.
  static const double navGlideSink = 0.9;

  /// How much the whole bar swells while it is held.
  static const double navHeldSwell = 0.03;

  /// How much a held drop of liquid glass swells out of its bar, and how
  /// far a touch moves before it is a drag.
  static const double liquidSwell = 0.32;
  static const double dragSlop = 8;

  /// How much a picked choice swells, and the room kept round a stretched
  /// thumb for its shadow.
  static const double liquidPop = 0.07;
  static const double liquidPopCard = 0.025;
  static const double liquidShadowRoom = 12;

  /// How far a switch's knob stretches along its track as it turns to
  /// glass.
  static const double switchGlassStretch = 0.6;

  /// The main action key's soft glow.
  static const double keyGlowSpread = 10;
  static const double keyGlowBlur = 12;

  /// Going back with a swipe: how near the edge it must start, how far or
  /// how fast (logical pixels a second) it must go, and the moving page's
  /// shadow.
  static const double swipeBackEdge = 20;
  static const double swipeBackShare = 0.35;
  static const double swipeBackFling = 700;
  static const double swipeBackShadow = 18;

  /// A list row: its least height and the tinted tile at its start.
  static const double listRowMinHeight = 52;
  static const double toneTile = 38;

  /// The dot that marks something unread.
  static const double unreadDot = 8;

  /// A filter chip's height.
  static const double chipHeight = 34;

  /// A switch: its track and the knob on it.
  static const double switchWidth = 46;
  static const double switchHeight = 28;
  static const double switchKnob = 22;

  /// A progress step's dot, the current one's, and its halo.
  static const double stepDot = 10;
  static const double stepDotCurrent = 12;
  static const double stepHalo = 4;
  static const double stepLine = 2;

  /// The large avatar on the profile.
  static const double profileAvatar = 56;

  /// The 3D tile of an empty list.
  static const double emptyTile = 64;

  /// One cell of the one-time code.
  static const double otpCellWidth = 48;
  static const double otpCellHeight = 56;

  // HRMS.
  static const double pageWash = 320;
  static const double pagePattern = 300;
  static const double ringGauge = 76;
  static const double ringGaugeStroke = 8;
  static const double ringGaugeDrop = 3;
  static const double progressTrack = 8;
  static const double progressTrackTall = 10;
  static const double progressThin = 6;

  // e Inspection.
  static const double planRing = 116;
  static const double planRingStroke = 14;
  static const double rowTile = 42;

  // PRAMS.
  static const double reportTile = 72;
  static const double weekBars = 60;
  static const double weekBarsWidth = 104;

  // Selection controls.
  static const double minTouch = 44;
  static const double checkbox = 24;
  static const double checkboxGlyph = 14;
  static const double radioDot = 10;
  static const double stepperKey = 36;
  static const double stepperValue = 24;
  static const double chip = 38;
  static const double chipCheck = 18;
  static const double chipCheckGlyph = 11;
  static const double stepNumber = 20;

  /// The least line between two steps of a step header.
  static const double stepGapMin = 24;

  // Loader.
  static const double loader = 76;
  static const double loaderSmall = 52;
  static const double loaderStrokeShare = 0.055;
  static const double loaderDiscShare = 0.74;
  static const double loaderEmblemShare = 0.48;
  static const double dash = 4;
  static const double photoTile = 92;
  static const double trainCodeWidth = 52;
  static const double trainCodeHeight = 38;
  static const double progressMark = 14;
  static const double progressMarkWidth = 2;
  static const double statMark = 8;
  static const double statMarkRadius = 3;
  static const double statusDot = 7;
  static const double linkThumb = 52;
  static const double actionIcon = 50;
  static const double choiceCheck = 18;
  static const double choiceCheckGlyph = 11;
  static const double calendarDay = 36;
  static const double todayRing = 2;
  static const double calendarTile = 38;
  static const double calendarNav = 36;
  static const double legendSwatch = 10;
  static const double avatarSmall = 36;
  static const double avatarMedium = 42;
  static const double avatarLarge = 72;
  static const double stackedBar = 8;
  static const double stackedBarGap = 2;
  static const double heroButton = 52;

  // Document camera.
  static const double shutter = 72;
  static const double frameCorner = 26;
  static const double frameCornerStroke = 4;

  // Appearance picker.
  static const double appearanceSwatch = 44;
  static const double appearanceBarWidth = 30;
  static const double appearanceBarHeight = 5;

  // Face camera.
  static const double faceGuideStroke = 4;
  static const double faceGuideProgress = 5;
  static const double faceGuideDash = 36;
  static const double faceGuideGap = 10;
  static const double checkSpinner = 18;

  // Sheets and search.
  static const double sheetClose = 36;
  static const double searchField = 48;

  // Banners.
  static const double heroPattern = 140;
  static const double heroRing = 68;
  static const double heroRingStroke = 7;

  // Home header.
  static const double homeLogo = 56;
  static const double homeLogoEmblem = 46;

  // Splash.
  /// Options shown as cards: how many to a row, the mark on each, and the
  /// ring a picked one wears.
  static const int optionGridColumns = 3;
  static const double optionCardMark = 44;
  static const double optionCardRing = 2;

  /// The company's logo in the "Powered by" line.
  static const double poweredByLogo = 26;

  static const double splashTagline = 440;
  static const double ruleThickness = 1.5;

  /// The logo on the sign-in tab.
  static const double tabLogo = 20;

  /// How far a piece of the sign-in screen rises as it comes in, and how
  /// far its card shakes at a failed sign-in.
  static const double riseDistance = 24;
  static const double shakeDistance = 10;

  /// The biometric sign-in key: its height, corners and the badge round
  /// its mark.
  static const double biometricKeyHeight = 54;
  static const double biometricKeyRadius = 16;
  static const double biometricBadge = 34;

  /// How far apart the small capitals over a card's title stand.
  static const double eyebrowTracking = 1.6;

  /// The initials on the profile's banner.
  static const double profileHeroAvatar = 64;

  /// A leave type's card in the row of balances.
  static const double leaveCard = 116;
}
