import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How large the whole app is drawn, as the iPhone's Display Zoom sets it:
/// buttons, icons and text together, not the text alone.
enum DisplaySize {
  standard(1),
  large(1.15);

  const DisplaySize(this.scale);

  /// How much larger than the phone draws it.
  final double scale;
}

/// The size and weight of the app's text, and the size of everything else,
/// as the user sets them on the profile, over what the phone asks for.
@immutable
class TextLook {
  const TextLook({
    this.size = defaultSize,
    this.bold = false,
    this.display = DisplaySize.standard,
  });

  /// The sizes to choose from, smallest first, as shares of the phone's
  /// own text size.
  static const List<double> sizes = [0.9, 1, 1.12, 1.25, 1.4];

  /// The size until the user picks one: the phone's own.
  static const int defaultSize = 1;

  /// Which of [sizes] it is.
  final int size;
  final bool bold;
  final DisplaySize display;

  double get scale => sizes[size];

  TextLook copyWith({int? size, bool? bold, DisplaySize? display}) => TextLook(
    size: size ?? this.size,
    bold: bold ?? this.bold,
    display: display ?? this.display,
  );

  @override
  bool operator ==(Object other) =>
      other is TextLook &&
      other.size == size &&
      other.bold == bold &&
      other.display == display;

  @override
  int get hashCode => Object.hash(size, bold, display);
}

/// Holds the [TextLook], remembered across launches and sign-ins.
class TextLookController extends ValueNotifier<TextLook> {
  TextLookController() : super(const TextLook());

  /// The size is kept as its scale, so it survives a change to [TextLook.sizes].
  static const _sizeKey = 'text_scale';
  static const _boldKey = 'text_bold';
  static const _displayKey = 'display_size';

  /// Reads what was remembered, if anything.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scale = prefs.getDouble(_sizeKey);
      value = TextLook(
        size: scale == null ? TextLook.defaultSize : _nearest(scale),
        bold: prefs.getBool(_boldKey) ?? false,
        display:
            DisplaySize.values.asNameMap()[prefs.getString(_displayKey)] ??
            DisplaySize.standard,
      );
    } catch (error) {
      debugPrint('Reading the text look failed: $error');
    }
  }

  static int _nearest(double scale) {
    var best = TextLook.defaultSize;
    for (var i = 0; i < TextLook.sizes.length; i++) {
      if ((TextLook.sizes[i] - scale).abs() <
          (TextLook.sizes[best] - scale).abs()) {
        best = i;
      }
    }
    return best;
  }

  /// Shows [look] and remembers it.
  Future<void> pick(TextLook look) async {
    value = look;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_sizeKey, look.scale);
      await prefs.setBool(_boldKey, look.bold);
      await prefs.setString(_displayKey, look.display.name);
    } catch (error) {
      debugPrint('Saving the text look failed: $error');
    }
  }
}
