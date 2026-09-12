import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShahkarTheme {
  static const _seed = Color(0xFF1B6BFF);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final text = GoogleFonts.vazirmatnTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
    );
  }
}
