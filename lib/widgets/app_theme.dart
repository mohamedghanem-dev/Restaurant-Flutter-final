import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors inspired by the poster
  static const primary    = Color(0xFFE8680A);   // deep orange-fire
  static const primaryDark= Color(0xFFBF4F00);
  static const gold       = Color(0xFFF5C518);   // golden yellow
  static const goldDark   = Color(0xFFDAA520);
  static const goldLight  = Color(0xFFFFE082);
  static const ember      = Color(0xFFFF6B00);   // glowing ember

  // Backgrounds
  static const bg         = Color(0xFF080808);
  static const surface    = Color(0xFF121212);
  static const surface2   = Color(0xFF1A1A1A);
  static const surface3   = Color(0xFF222222);
  static const border     = Color(0xFF2C2C2C);
  static const borderGold = Color(0xFF3A2800);

  // Text
  static const textColor  = Color(0xFFF2F2F2);
  static const textSub    = Color(0xFFB0B0B0);
  static const muted      = Color(0xFF777777);

  // Status
  static const green      = Color(0xFF22C55E);
  static const red        = Color(0xFFEF4444);
  static const blue       = Color(0xFF3B82F6);

  static const gradient = LinearGradient(
    colors: [ember, primary, primaryDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const goldGradient = LinearGradient(
    colors: [goldDark, gold, goldLight, gold, goldDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1A0800), Color(0xFF0A0500)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.cairo().fontFamily,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary, secondary: gold,
      surface: surface, background: bg,
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: textColor),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: TextStyle(
        color: textColor, fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
  );
}

const kStatusColors = {
  'pending':   Color(0xFFE8680A),
  'preparing': Color(0xFFF5C518),
  'ready':     Color(0xFF22C55E),
  'delivered': Color(0xFF777777),
  'cancelled': Color(0xFFEF4444),
};

const kStatusLabels = {
  'pending':   '⏳ قيد التحضير',
  'preparing': '👨‍🍳 يتحضر',
  'ready':     '✅ جاهز',
  'delivered': '🚚 تم التسليم',
  'cancelled': '❌ ملغي',
};
