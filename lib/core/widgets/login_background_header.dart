import 'package:flutter/material.dart';

class LoginBackgroundHeader extends StatelessWidget {
  final double? height;
  final double? overlayHeight;
  final String imagePath;
  final Color overlayColor;
  final double overlayAlpha;
  final BoxFit fit;

  const LoginBackgroundHeader({
    super.key,
    this.height,
    this.overlayHeight,
    this.imagePath = 'assets/bg_railway.webp',
    this.overlayColor = const Color(0xFFF1F5F9),
    this.overlayAlpha = 0.65,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bgHeight = height ?? screenHeight * 0.65;
    final ovHeight = overlayHeight ?? screenHeight * 0.38;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: bgHeight,
          child: Image.asset(imagePath, fit: fit, alignment: Alignment.center),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: ovHeight,
          child: Container(color: overlayColor.withValues(alpha: overlayAlpha)),
        ),
      ],
    );
  }
}
