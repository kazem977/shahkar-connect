import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShahkarTheme {
  static const _seed = Color(0xFF1E3A5F);
  static const connected = Color(0xFF22C55E);
  static const canvasDark = Color(0xFF0F172A);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final text = GoogleFonts.vazirmatnTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? canvasDark : scheme.surface,
    );
  }
}
