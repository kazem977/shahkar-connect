import 'package:flutter/material.dart';

/// The "VPNAI" wordmark: Inter with a platinum-to-indigo sheen, an ambient
/// glow and an optional fading rule underneath.
class VpnaiWordmark extends StatelessWidget {
  const VpnaiWordmark({
    super.key,
    this.fontSize = 20,
    this.glow = true,
    this.underline = false,
    this.dim = false,
  });

  /// Cap height of the wordmark.
  final double fontSize;

  /// Soft indigo halo behind the letters.
  final bool glow;

  /// Fading hairline centred below the letters.
  final bool underline;

  /// Quieter grey sheen for chrome and dense surfaces.
  final bool dim;

  static const _bright = [
    Color(0xFFFFFFFF),
    Color(0xFFEFF2FF),
    Color(0xFFB6BEFF),
  ];

  static const _quiet = [
    Color(0xFFE7EBF2),
    Color(0xFFB9C1CE),
    Color(0xFF8D96A6),
  ];

  static const _text = 'VPNAI';

  @override
  Widget build(BuildContext context) {
    final spacing = fontSize * (dim ? 0.12 : 0.20);
    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: spacing,
      height: 1,
      color: Colors.white,
    );

    Widget letters = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dim ? _quiet : _bright,
        stops: const [0.0, 0.62, 1.0],
      ).createShader(bounds),
      child: Text(_text, style: style),
    );

    if (glow) {
      letters = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            _text,
            style: style.copyWith(
              color: Colors.transparent,
              shadows: [
                Shadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.34),
                  blurRadius: fontSize * 0.7,
                ),
              ],
            ),
          ),
          letters,
        ],
      );
    }

    // Tracking adds a gap after the last letter; nudge back to optical centre.
    letters = Transform.translate(
      offset: Offset(spacing / 2, 0),
      child: letters,
    );

    if (!underline) return letters;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        letters,
        SizedBox(height: fontSize * 0.34),
        Container(
          width: fontSize * 3.0,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.0),
                const Color(0xFF8B83FF),
                const Color(0xFF6C63FF).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
