import 'package:flutter/material.dart';

class ShahkarTheme {
  static const ink = Color(0xFF05060A);
  static const forest = ink;
  static const fog = Color(0xFFF2F4FA);
  static const mute = Color(0xFF8B93A7);
  static const accent = Color(0xFF8B7CFF);
  static const accentSoft = Color(0xFFA89BFF);
  static const accentDeep = Color(0xFF5B4FE0);
  static const brandCyan = Color(0xFF46B8E9);
  static const connected = Color(0xFF3DDC97);
  static const protectedTeal = Color(0xFF4ED9B2);
  static const upload = Color(0xFFFF6B7A);
  static const gold = accent;
  static const canvasDark = ink;
  static const line = Color(0xFF1A1E2A);
  static const danger = Color(0xFFE07A7A);
  static const surface = Color(0xFF12141C);
  static const surfaceElevated = Color(0xFF181B26);
  static const navBar = Color(0xFF0C0E14);

  static ThemeData dark(Locale locale) => _build(locale);

  static String _family(Locale locale) =>
      locale.languageCode == 'fa' ? 'Vazirmatn' : 'Inter';

  static ThemeData _build(Locale locale) {
    const scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: fog,
      secondary: protectedTeal,
      onSecondary: ink,
      error: danger,
      onError: fog,
      surface: ink,
      onSurface: fog,
      outline: line,
    );
    final family = _family(locale);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: family,
      fontFamilyFallback: const [
        'Vazirmatn',
        'Inter',
        'Segoe UI',
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans SC',
      ],
    );
    return base.copyWith(
      scaffoldBackgroundColor: ink,
      visualDensity: VisualDensity.compact,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: fog,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 44,
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: fog,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.75)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: mute, fontSize: 13),
        hintStyle: TextStyle(color: mute.withValues(alpha: 0.75), fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: fog,
          disabledBackgroundColor: accent.withValues(alpha: 0.28),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mute,
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surface,
        textStyle: TextStyle(color: fog, fontSize: 13),
      ),
    );
  }
}
