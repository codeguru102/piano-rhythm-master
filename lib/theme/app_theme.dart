import 'package:flutter/material.dart';

/// Central design system for Piano Rhythm Master.
/// Dark, high-contrast, neon-accented — premium mobile game feel.
class AppColors {
  // Backgrounds
  static const Color bg = Color(0xFF07060D);
  static const Color bgElevated = Color(0xFF0F0E1A);
  static const Color panel = Color(0xFF15132A);
  static const Color panelHi = Color(0xFF1D1A38);
  static const Color stroke = Color(0x1FFFFFFF);

  // Neon accents
  static const Color neonBlue = Color(0xFF3D8BFF);
  static const Color neonPurple = Color(0xFF9B5CFF);
  static const Color neonPink = Color(0xFFFF4D9D);
  static const Color neonCyan = Color(0xFF33E1ED);
  static const Color neonMint = Color(0xFF5CF2C4);

  // Ornate gold accents
  static const Color gold = Color(0xFFFFD76B);
  static const Color gold2 = Color(0xFFFFA92E);

  // Text
  static const Color textHi = Color(0xFFF5F4FF);
  static const Color textMid = Color(0xFFB7B4D1);
  static const Color textLow = Color(0xFF6E6A8F);

  // Difficulty
  static const Color easy = Color(0xFF3DDC84);
  static const Color normal = Color(0xFF3D8BFF);
  static const Color hard = Color(0xFF9B5CFF);
  static const Color expert = Color(0xFFFF4D5E);

  // Judgment feedback
  static const Color perfect = Color(0xFF33E1ED);
  static const Color great = Color(0xFF3DDC84);
  static const Color good = Color(0xFFFFC24B);
  static const Color miss = Color(0xFFFF4D5E);
}

/// Per-lane accent colors (C D E F G).
const List<Color> kLaneColors = [
  Color(0xFF3D8BFF), // blue
  Color(0xFF33E1ED), // cyan
  Color(0xFF9B5CFF), // purple
  Color(0xFFFF4D9D), // pink
  Color(0xFFFF6A3D), // orange
];

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonPurple, AppColors.neonPink],
  );

  static const LinearGradient cool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonBlue, AppColors.neonCyan],
  );

  /// Lush multi-stop aurora used for titles and hero accents.
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.neonCyan,
      AppColors.neonBlue,
      AppColors.neonPurple,
      AppColors.neonPink,
    ],
  );

  static const LinearGradient royal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.neonPurple, AppColors.neonPink, AppColors.gold],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold, AppColors.gold2],
  );

  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.panelHi, AppColors.panel],
  );

  static const RadialGradient stage = RadialGradient(
    center: Alignment(0, -0.6),
    radius: 1.4,
    colors: [Color(0xFF1A1636), AppColors.bg],
  );

  /// A gradient chosen deterministically for a song cover.
  static LinearGradient cover(int seed) {
    const palettes = [
      [Color(0xFF9B5CFF), Color(0xFFFF4D9D)],
      [Color(0xFF3D8BFF), Color(0xFF33E1ED)],
      [Color(0xFFFF6A3D), Color(0xFFFF4D9D)],
      [Color(0xFF3DDC84), Color(0xFF33E1ED)],
      [Color(0xFF7B5CFF), Color(0xFF3D8BFF)],
      [Color(0xFFFF4D5E), Color(0xFF9B5CFF)],
    ];
    final p = palettes[seed % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: p,
    );
  }
}

class AppRadii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double pill = 999;
}

class AppSpace {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 36;
}

/// Reusable neon glow shadow.
List<BoxShadow> glow(Color color, {double blur = 24, double spread = 0, double opacity = 0.55}) {
  return [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: spread,
    ),
  ];
}

ThemeData buildAppTheme() {
  const fontFamily = 'Rubik';
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.neonPurple,
      secondary: AppColors.neonPink,
      surface: AppColors.panel,
      onSurface: AppColors.textHi,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: AppColors.textHi,
      displayColor: AppColors.textHi,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textHi,
    ),
  );
}
