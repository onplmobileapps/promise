import 'package:flutter/material.dart';

class AccidentReportSubmittedScreen extends StatelessWidget {
  const AccidentReportSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        // Fills a tall screen; scrolls on a short one, as a phone on its side.
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Custom Document Illustration
                      const CustomDocumentIllustration(),
                      const SizedBox(height: 36),

                      // Title
                      const Text(
                        'Accident Report Submitted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'Accident alert successfully broadcasted\nacross all channels',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const Spacer(),

                      // Go to Home Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Go to Home',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CUSTOM ILLUSTRATION WIDGET ────────────────────────────────────────────────

class CustomDocumentIllustration extends StatelessWidget {
  const CustomDocumentIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Green Oval Platform
          Positioned(
            bottom: 10,
            child: Container(
              width: 170,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E),
                borderRadius: BorderRadius.all(Radius.elliptical(170, 32)),
                border: Border.all(color: const Color(0xFF13362B), width: 2),
              ),
            ),
          ),

          // Stacked Background Page 1
          Positioned(
            top: 25,
            child: Container(
              width: 110,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
              ),
            ),
          ),

          // Stacked Background Page 2
          Positioned(
            top: 30,
            left: 52,
            child: Container(
              width: 110,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
              ),
            ),
          ),

          // Main Foreground Document Page with Folded Corner
          Positioned(
            top: 38,
            left: 42,
            child: Container(
              width: 115,
              height: 135,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  8,
                  (index) => Container(
                    height: 1.5,
                    color: Colors.grey.shade400,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
              ),
            ),
          ),

          // Top Right Fold Ribbon Accent
          Positioned(
            top: 38,
            right: 43,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF1B4D3E),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
              ),
            ),
          ),

          // Center Checkmark Badge
          Positioned(
            top: 72,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF28A745),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1B4D3E), width: 2.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
