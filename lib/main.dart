import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Railway HRMS',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.green)),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayeredGradientBackground(child: Container());
  }
}

class LayeredGradientPainter extends CustomPainter {
  final double opacity; // Control overall opacity

  const LayeredGradientPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Layer 1: Base color with opacity control
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF015E35).withOpacity(opacity * 0.9),
          Color(0xFF015E35).withOpacity(opacity * 0.7),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint1);

    // Layer 2: Warm overlay with transparency
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Color.fromARGB(0, 249, 187, 1).withOpacity(opacity * 0.3),
          Color(0xFF002213).withOpacity(opacity * 0.4),
        ],
        stops: const [0.3, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint2);

    // Layer 3: Accent color with blending
    final paint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(13, 218, 71, 13).withOpacity(opacity * 0.15),
          Color.fromRGBO(249, 187, 1, 0.5).withOpacity(opacity * 0.1),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint3);

    // Layer 4: Soft shadow overlay
    final paint4 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(opacity * 0.15),
          Colors.transparent,
          Colors.black.withOpacity(opacity * 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint4);
  }

  @override
  bool shouldRepaint(covariant LayeredGradientPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
class LayeredGradientBackground extends StatelessWidget {
  final Widget? child;
  final double opacity;
  final GradientStyle style;
  final EdgeInsetsGeometry? padding;

  const LayeredGradientBackground({
    super.key,
    this.child,
    this.opacity = 0.8,
    this.style = GradientStyle.default_,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: CustomPaint(
        painter: LayeredGradientPainter(
          opacity: opacity,
        ),
        size: Size.infinite,
        child: child ?? Container(),
      ),
    );
  }
}

enum GradientStyle {
  default_,
  light,
  dark,
  vibrant,
}

// Alternative: Predefined gradient styles
class GradientPresets {
  static const light = 0.4;
  static const medium = 0.7;
  static const dark = 0.9;
  static const transparent = 0.2;
}