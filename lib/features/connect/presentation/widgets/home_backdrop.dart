import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shahkar_connect/theme.dart';

/// Professional home backdrop using the provided world-map artwork.
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF05060A)),
        // Soft teal grid at top
        CustomPaint(painter: _GridPainter()),
        // World map asset — centered behind the power button
        Align(
          alignment: Alignment(0, -0.12.h),
          child: Opacity(
            opacity: connected ? 0.92 : 0.78,
            child: Image.asset(
              'assets/brand/world-map-bg.jpg',
              width: 420.w,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              color: Colors.black.withValues(alpha: 0.35),
              colorBlendMode: BlendMode.darken,
            ),
          ),
        ),
        // Teal glow over the map
        Align(
          alignment: const Alignment(0, -0.05),
          child: Container(
            width: 300.w,
            height: 300.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ShahkarTheme.protectedTeal
                      .withValues(alpha: connected ? 0.32 : 0.18),
                  ShahkarTheme.protectedTeal.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Fade into lower UI
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Container(
              height: 240.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x9905060A),
                    Color(0xFF05060A),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ShahkarTheme.protectedTeal.withValues(alpha: 0.09)
      ..strokeWidth = 1;
    const step = 16.0;
    final gridH = size.height * 0.30;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, gridH), paint);
    }
    for (var y = 0.0; y < gridH; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, gridH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF05060A).withValues(alpha: 0.92),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, gridH)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
