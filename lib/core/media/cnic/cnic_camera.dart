import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/camera/camera_flash_switch.dart';
import 'package:railway_hrms/core/media/camera/card_camera_window.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';
import 'package:railway_hrms/core/media/camera/live_camera.dart';
import 'package:railway_hrms/core/media/cnic/cnic_check.dart';
import 'package:railway_hrms/core/media/cnic/cnic_crop.dart';
import 'package:railway_hrms/core/media/cnic/cnic_vision.dart';

/// A scanned CNIC or NICOP: the photo of its front, cropped to the card.
@immutable
class CnicScan {
  const CnicScan({required this.photo});

  final XFile photo;
}

/// The camera window's width to its height: wide enough round the card for
/// its corners and the AI's badge under it.
const _windowAspect = 1.25;

/// A frame darker than this, its luma's mean from 0 to 255, is too dark to
/// tell a card in.
const _darkBelow = 45.0;

/// A frame less sharp than this, the variance of its luma's Laplacian, is
/// blurred: the user is asked to hold steady.
const _blurBelow = 25.0;

/// How long a card seen is remembered, to say its picture is blurred even
/// when the blur hides it.
const _cardMemory = Duration(seconds: 2);

/// How long the tick shows once the CNIC is taken.
const _tick = Duration(milliseconds: 450);

/// What the scan is doing, the camera open.
enum _Stage { scanning, reading, verified }

/// How the camera's picture looks, for the hint: fine, too dark or
/// blurred.
enum _Look { fine, dark, blurry }

/// The camera that takes the front of a Pakistani CNIC or NICOP, old or
/// new, English or Urdu, laid into a page. Only the card's frame shows the
/// camera. While the user fits the card in it, on-device AI says what it
/// sees: the card's pale green and its holder's photo ([CnicCheck]), a
/// card too far, a wrong card, too little light or a blurred picture. The
/// user takes the photo with the shutter; the AI checks it, and anything
/// but a CNIC, such as a bank card, another card or a photo too unclear to
/// tell, is called out in a dialog. The phone's light is the user's to
/// switch on.
///
/// The camera itself is a [LiveCamera] in a [CardCameraWindow]; this is
/// what makes it a CNIC's.
class CnicCamera extends StatefulWidget {
  const CnicCamera({
    super.key,
    required this.onCaptured,
    required this.onClose,
  });

  /// Called with the scan once the card is taken.
  final ValueChanged<CnicScan> onCaptured;

  /// Called when the user closes the camera, or doesn't allow it.
  final VoidCallback onClose;

  @override
  State<CnicCamera> createState() => _CnicCameraState();
}

class _CnicCameraState extends State<CnicCamera> {
  final _vision = CnicVision();
  late final _camera = LiveCamera(
    onFrame: _glance,
    // The frame sits a little above the window's middle.
    focusPoint: const Offset(0.5, 0.46),
  );
  _Stage _stage = _Stage.scanning;
  CnicSighting _sighting = CnicSighting.nothing;
  _Look _look = _Look.fine;

  /// When a card was last seen in a frame.
  DateTime _cardSeenAt = DateTime(0);

  /// A dialog is up: frames are let go.
  bool _paused = false;

  /// The camera window's size, to map it onto frames and photos.
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    // The frame is drawn upright and the frames are looked at upright.
    unawaited(AppOrientation.holdUpright());
    _camera.addListener(_redraw);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    unawaited(AppOrientation.apply());
    _camera
      ..removeListener(_redraw)
      ..dispose();
    unawaited(_vision.close());
    super.dispose();
  }

  Future<void> _open() async {
    if (!mounted) return;
    if (!await _camera.open(context) && mounted) widget.onClose();
  }

  /// The camera opened, closed or switched its light.
  void _redraw() {
    if (mounted) setState(() {});
  }

  Future<void> _glance(CameraImage image) async {
    if (_paused || _stage != _Stage.scanning || !mounted) return;
    final session = _camera.session;
    bool stale() =>
        !mounted ||
        session != _camera.session ||
        _paused ||
        _stage != _Stage.scanning;
    final rotation = _camera.rotation;
    final turned = rotation == 90 || rotation == 270;
    final upright = turned
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());
    if (_viewport.isEmpty) return;
    final window = viewToImage(
      cardFrameIn(_viewport),
      view: _viewport,
      image: upright,
    );
    // Too dark or too blurred, the user is told why.
    final look = CnicVision.lookOf(image, rotation, window);
    final quality = look == null
        ? _Look.fine
        : look.brightness < _darkBelow
        ? _Look.dark
        : look.sharpness < _blurBelow
        ? _Look.blurry
        : _Look.fine;
    if (quality == _Look.dark) {
      // Nothing can be told in the dark; the hint says what to do.
      if (_look != _Look.dark) setState(() => _look = _Look.dark);
      return;
    }
    final green = CnicVision.greenOf(image, rotation, window);
    final sight = await _vision.readFrame(image, rotation);
    if (sight == null || stale()) return;
    final sighting = CnicCheck.glance(
      lines: sight.lines,
      faces: sight.faces,
      green: green,
      window: window,
    );
    final now = DateTime.now();
    if (sighting != CnicSighting.nothing) _cardSeenAt = now;
    // Blur is spoken of only with a card in view: before one is held up,
    // the camera is just looking at the room.
    final shown =
        quality == _Look.blurry &&
            sighting == CnicSighting.nothing &&
            now.difference(_cardSeenAt) > _cardMemory
        ? _Look.fine
        : quality;
    if (shown != _look || sighting != _sighting) {
      setState(() {
        _look = shown;
        _sighting = sighting;
      });
    }
  }

  /// Takes the photo, crops it to the card's frame and has the AI look at
  /// it: only a CNIC or a NICOP is kept; anything else is said in a dialog.
  Future<void> _capture() async {
    if (!_camera.isReady || _stage != _Stage.scanning || _paused) return;
    final session = _camera.session;
    final viewport = _viewport;
    setState(() => _stage = _Stage.reading);
    unawaited(HapticFeedback.selectionClick());
    final CnicCut cut;
    final CnicProblem? problem;
    try {
      final shot = await _camera.takePicture();
      if (!mounted || session != _camera.session) {
        // The camera went meanwhile: back to looking once it is back.
        await _rescan();
        return;
      }
      final cropped = await cropCnic(shot, cardFrameIn(viewport), viewport);
      if (cropped == null) throw StateError('The photo could not be read');
      cut = cropped;
      // The card's JPEG is written while it is looked at.
      unawaited(cut.file);
      final sight = await _vision.readPixels(cut.pixels, cut.width, cut.height);
      final size = Size(cut.width.toDouble(), cut.height.toDouble());
      problem = CnicCheck.photo(
        lines: sight.lines,
        faces: sight.faces,
        green: CnicVision.greenOfPixels(
          cut.pixels,
          stride: cut.width * 4,
          width: cut.width,
          height: cut.height,
          layout: PixelLayout.rgba,
          window: Offset.zero & size,
        ),
        size: size,
      );
    } catch (error) {
      debugPrint('The CNIC photo failed: $error');
      await _rescan();
      return;
    }
    if (!mounted) return;
    if (problem != null) {
      await _reject(problem);
      return;
    }
    setState(() => _stage = _Stage.verified);
    unawaited(HapticFeedback.mediumImpact());
    try {
      // The photo is the card's now: the camera may go meanwhile.
      final (photo, _) = await (cut.file, Future<void>.delayed(_tick)).wait;
      if (mounted) widget.onCaptured(CnicScan(photo: photo));
    } catch (error) {
      debugPrint('The CNIC photo could not be saved: $error');
      await _rescan();
    }
  }

  /// Back to looking for a CNIC.
  Future<void> _rescan() async {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.scanning;
      _look = _Look.fine;
      _sighting = CnicSighting.nothing;
    });
    await _camera.resumeFrames();
  }

  /// Says what is wrong with the photo taken, then looks again, or closes
  /// the camera if asked.
  Future<void> _reject(CnicProblem problem) async {
    if (_paused || !mounted) return;
    _paused = true;
    setState(() => _stage = _Stage.scanning);
    unawaited(HapticFeedback.heavyImpact());
    await _camera.pauseFrames();
    if (!mounted) return;
    final l10n = context.l10n;
    final (title, message, tone) = switch (problem) {
      CnicProblem.bankCard => (
        l10n.cnicWrongBankTitle,
        l10n.cnicWrongBankMessage,
        AppDialogTone.error,
      ),
      CnicProblem.otherCard => (
        l10n.cnicWrongCardTitle,
        l10n.cnicWrongCardMessage,
        AppDialogTone.error,
      ),
      CnicProblem.notCnic => (
        l10n.cnicWrongCardTitle,
        l10n.cnicNotCnicMessage,
        AppDialogTone.error,
      ),
      CnicProblem.nothing => (
        l10n.cnicNothingTitle,
        l10n.cnicNothingMessage,
        AppDialogTone.warning,
      ),
    };
    final again = await showAppDialog(
      context: context,
      tone: tone,
      title: title,
      message: message,
      primaryLabel: l10n.actionRetry,
      secondaryLabel: l10n.actionClose,
    );
    _paused = false;
    if (!mounted) return;
    if (again == false) {
      widget.onClose();
      return;
    }
    await _rescan();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final busy = _stage != _Stage.scanning;
    final (hint, tone, dot) = _hint(l10n, colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (_camera.hasTorch)
              CameraFlashSwitch(
                on: _camera.torch,
                onChanged: !_camera.isReady || busy ? null : _camera.setTorch,
              ),
            const Spacer(),
            AppTileButton(
              icon: const AppGlyphIcon(AppGlyphs.close),
              tooltip: l10n.actionClose,
              onPressed: busy ? null : widget.onClose,
            ),
          ],
        ),
        AppSpacing.gapSm,
        AspectRatio(
          aspectRatio: _windowAspect,
          child: CardCameraWindow(
            camera: _camera,
            corners: _corners(colors),
            beam: switch (_stage) {
              _Stage.scanning => colors.success,
              _Stage.reading => colors.gold,
              _Stage.verified => null,
            },
            badge: AppPill(
              l10n.cnicLiveBadge,
              tone: AppTone.brand,
              dot: colors.success,
            ),
            ticked: _stage == _Stage.verified,
            onViewport: (size) => _viewport = size,
          ),
        ),
        AppSpacing.gapMd,
        Center(
          child: Semantics(
            liveRegion: true,
            child: AppPill(hint, tone: tone, dot: dot),
          ),
        ),
        AppSpacing.gapLg,
        Center(
          child: AppActionKey(
            icon: AppGlyphIcon(
              AppGlyphs.camera,
              size: AppSizes.iconLg,
              color: colors.onPrimary,
            ),
            label: l10n.cnicCapture,
            isLoading: _stage == _Stage.reading,
            size: AppSizes.shutter,
            onPressed: _camera.isReady && !busy && !_paused ? _capture : null,
          ),
        ),
      ],
    );
  }

  /// A wrong card is in front of the camera: that is said first.
  bool get _wrongCard =>
      _sighting == CnicSighting.bankCard ||
      _sighting == CnicSighting.otherCard ||
      _sighting == CnicSighting.notCnic;

  /// The frame's corners: lit by what the camera sees.
  Color _corners(AppColors colors) => switch (_stage) {
    _Stage.verified => colors.success,
    _Stage.reading => colors.gold,
    _Stage.scanning when !_camera.isReady => colors.outlineStrong,
    _Stage.scanning when _look != _Look.fine && !_wrongCard => colors.gold,
    _Stage.scanning => switch (_sighting) {
      CnicSighting.cnic => colors.success,
      CnicSighting.far => colors.gold,
      CnicSighting.bankCard ||
      CnicSighting.otherCard ||
      CnicSighting.notCnic => colors.danger,
      CnicSighting.nothing || CnicSighting.card => colors.iconAccent,
    },
  };

  /// What the pill under the camera says, its tint, and its dot.
  (String, AppTone, Color) _hint(AppLocalizations l10n, AppColors colors) {
    if (_camera.status == LiveCameraStatus.failed) {
      return (l10n.cnicCameraFailed, AppTone.danger, colors.danger);
    }
    if (!_camera.isReady && _stage == _Stage.scanning) {
      return (l10n.cnicHintStarting, AppTone.neutral, colors.warningMark);
    }
    return switch (_stage) {
      _Stage.reading => (l10n.cnicHintReading, AppTone.warning, colors.gold),
      _Stage.verified => (l10n.cnicHintVerified, AppTone.brand, colors.success),
      _Stage.scanning when _look == _Look.dark && !_wrongCard => (
        _camera.torch ? l10n.cnicHintDarkFlashOn : l10n.cnicHintDark,
        AppTone.warning,
        colors.gold,
      ),
      _Stage.scanning when _look == _Look.blurry && !_wrongCard => (
        l10n.cnicHintBlurry,
        AppTone.warning,
        colors.gold,
      ),
      _Stage.scanning => switch (_sighting) {
        CnicSighting.nothing => (
          l10n.cnicHintPlace,
          AppTone.neutral,
          colors.warningMark,
        ),
        CnicSighting.card => (
          l10n.cnicHintLooking,
          AppTone.neutral,
          colors.warningMark,
        ),
        CnicSighting.far => (l10n.cnicHintCloser, AppTone.warning, colors.gold),
        CnicSighting.cnic => (l10n.cnicHintHold, AppTone.brand, colors.success),
        CnicSighting.bankCard => (
          l10n.cnicHintBank,
          AppTone.danger,
          colors.danger,
        ),
        CnicSighting.otherCard || CnicSighting.notCnic => (
          l10n.cnicHintOther,
          AppTone.danger,
          colors.danger,
        ),
      },
    };
  }
}
