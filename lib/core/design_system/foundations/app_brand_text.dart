import 'package:flutter/widgets.dart';

final RegExp _brand = RegExp(r'^e(?=[\s-]?[A-Z])');

/// [text] as the brand writes a name of its own, with the leading "e" of
/// "e Inspection" or "e-Inspection" in italics; null for any other text.
InlineSpan? brandSpan(String text) => _brand.hasMatch(text)
    ? TextSpan(
        children: [
          const TextSpan(
            text: 'e',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          TextSpan(text: text.substring(1)),
        ],
      )
    : null;

/// [text] as a [Text], the brand's names with their italic "e".
Widget brandText(
  String text, {
  TextStyle? style,
  int? maxLines,
  TextOverflow? overflow,
  TextAlign? textAlign,
}) {
  final span = brandSpan(text);
  return span == null
      ? Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        )
      : Text.rich(
          span,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
}
