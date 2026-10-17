import 'dart:io';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';

class StoredImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget? placeholder;

  const StoredImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: FootplateFileUtils.resolveAbsolutePath(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _placeholder(context, loading: true);
        }
        return Image.file(
          File(snapshot.data!),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _placeholder(context),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context, {bool loading = false}) {
    if (placeholder != null) return placeholder!;
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Center(
        child: loading
            ? const AppLoader(size: AppSizes.loaderSmall)
            : AppGlyphIcon(AppGlyphs.image, color: colors.textTertiary),
      ),
    );
  }
}
