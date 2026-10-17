import 'dart:io';
import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.image_not_supported_outlined,
              color: scheme.onSurfaceVariant,
            ),
    );
  }
}
