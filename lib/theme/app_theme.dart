import 'package:flutter/material.dart';

/// Production design tokens for the "Neon Resonance" visual direction.
///
/// Existing aliases are retained while screens move toward semantic roles.
class AppColors {
  // Surfaces
  static const Color bg = Color(0xFF070812);
  static const Color bgElevated = Color(0xFF0C1020);
  static const Color panel = Color(0xFF101426);
  static const Color panelHi = Color(0xFF171C33);
  static const Color interactive = Color(0xFF202642);
  static const Color stroke = Color(0x24FFFFFF);
  static const Color strokeStrong = Color(0x3DFFFFFF);

  // Spectral accents
  static const Color neonBlue = Color(0xFF4A8EFF);
  static const Color neonPurple = Color(0xFF8B63FF);
  static const Color neonPink = Color(0xFFFF4D9D);
  static const Color neonCyan = Color(0xFF35D9F2);
  static const Color neonMint = Color(0xFF4DE2A8);

  // Reward accents
  static const Color gold = Color(0xFFFFC857);
  static const Color gold2 = Color(0xFFFF9F2E);

  // Text
  static const Color textHi = Color(0xFFF7F8FC);
  static const Color textMid = Color(0xFFAAB1C5);
  static const Color textLow = Color(0xFF747C94);

  // Difficulty
  static const Color easy = Color(0xFF4DE2A8);
  static const Color normal = Color(0xFF4A8EFF);
  static const Color hard = Color(0xFF8B63FF);
  static const Color expert = Color(0xFFFF5C73);

  // Judgment feedback
  static const Color perfect = Color(0xFF35D9F2);
  static const Color great = Color(0xFF4DE2A8);
  static const Color good = Color(0xFFFFC857);
  static const Color miss = Color(0xFFFF5C73);
}

/// Per-lane accent colors for the four piano columns.
const List<Color> kLaneColors = [
  AppColors.neonBlue,
  AppColors.neonCyan,
  AppColors.neonPurple,
  AppColors.neonPink,
];

class AppGradients {
  static const LinearGradient surfaceBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.strokeStrong, AppColors.stroke],
  );

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
    colors: [AppColors.neonPurple, AppColors.neonPink],
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
    colors: [Color(0xFF171631), AppColors.bg],
  );

  static LinearGradient cover(int seed) {
    const palettes = [
      [Color(0xFF8B63FF), Color(0xFFFF4D9D)],
      [Color(0xFF4A8EFF), Color(0xFF35D9F2)],
      [Color(0xFFFF704A), Color(0xFFFF4D9D)],
      [Color(0xFF4DE2A8), Color(0xFF35D9F2)],
      [Color(0xFF735CFF), Color(0xFF4A8EFF)],
      [Color(0xFFFF5C73), Color(0xFF8B63FF)],
    ];
    final palette = palettes[seed % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palette,
    );
  }
}

class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppMotion {
  static const Duration touch = Duration(milliseconds: 120);
  static const Duration state = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 340);
  static const Duration reward = Duration(milliseconds: 720);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve expressive = Curves.easeOutBack;
}

class AppTextStyles {
  static const TextStyle display = TextStyle(
    color: AppColors.textHi,
    fontSize: 44,
    height: 1.02,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.1,
  );

  static const TextStyle screenTitle = TextStyle(
    color: AppColors.textHi,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textHi,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textHi,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textHi,
    fontSize: 15,
    height: 1.4,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.textMid,
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.textMid,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

List<BoxShadow> glow(
  Color color, {
  double blur = 24,
  double spread = 0,
  double opacity = 0.55,
}) {
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
  const scheme = ColorScheme.dark(
    primary: AppColors.neonPurple,
    onPrimary: Colors.white,
    secondary: AppColors.neonCyan,
    onSecondary: Color(0xFF001F24),
    error: AppColors.miss,
    onError: Colors.white,
    surface: AppColors.panel,
    onSurface: AppColors.textHi,
    outline: AppColors.strokeStrong,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: scheme,
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
    dividerColor: AppColors.stroke,
    splashColor: Colors.white.withValues(alpha: 0.08),
    highlightColor: Colors.white.withValues(alpha: 0.04),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      hintStyle: const TextStyle(color: AppColors.textLow),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.4),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.neonCyan,
      linearTrackColor: AppColors.interactive,
      circularTrackColor: AppColors.interactive,
    ),
  );
}
