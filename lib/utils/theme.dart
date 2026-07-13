import 'package:flutter/material.dart';

/// Foodeez Partner brand palette — hex values sourced verbatim from the design prototype.
class AppColors {
  AppColors._();

  static const accent = Color(0xFF6E2A4D);
  static const accentLight = Color(0xFF8A3A66);
  static const accentDeep = Color(0xFF4E1D37);
  static const accentDeep2 = Color(0xFF7A2E56);

  static const gold = Color(0xFFC9A227);
  static const goldDark = Color(0xFF9C7614);
  static const goldBright = Color(0xFFF4D97A);

  static const green = Color(0xFF1F8A3B);
  static const greenDark = Color(0xFF177A33);
  static const greenPaleBg = Color(0xFFEAF6EE);
  static const greenPaleBg2 = Color(0xFFE7F4EA);
  static const greenPaleBorder = Color(0xFFBFE6C9);
  static const vegDot = Color(0xFF128A4B);

  static const red = Color(0xFFE23B3B);
  static const redDark = Color(0xFFC13A3A);
  static const redPaleBg = Color(0xFFFBEEEE);
  static const redPaleBg2 = Color(0xFFFBE6E6);
  static const redPaleBorder = Color(0xFFEAD9D9);
  static const nonVegDot = Color(0xFFB4442E);

  static const amber = Color(0xFFB4692E);
  static const amberDark = Color(0xFFC9821F);
  static const amberPaleBg = Color(0xFFFBF0DE);

  static const blue = Color(0xFF1D6FB8);
  static const bluePaleBg = Color(0xFFE4F0FA);
  static const bluePaleBg2 = Color(0xFFEAF0F6);
  static const bluePaleBorder = Color(0xFFC4DDF2);

  static const star = Color(0xFFF5A623);
  static const starPaleBg = Color(0xFFFBF4E4);

  static const ink = Color(0xFF1E1A1D);
  static const bodyGrey = Color(0xFF8A8189);
  static const lightGreyText = Color(0xFFB4A9AE);
  static const midGrey = Color(0xFF5C555A);
  static const chevronGrey = Color(0xFFC9BFC5);

  static const hairline = Color(0xFFF6F1ED);
  static const cardBorder = Color(0xFFF1ECE8);
  static const chipBorder = Color(0xFFEFEAE6);
  static const inputBorder = Color(0xFFE4DCE0);

  static const surface = Color(0xFFFBF8F4);
  static const surfaceWarm = Color(0xFFF7F4F0);
  static const neutralTint = Color(0xFFEDE7E2);
  static const neutralTint2 = Color(0xFFF1ECE8);
  static const neutralTint3 = Color(0xFFEDE7F1);

  static const maroonTint = Color(0xFFF6EEF3);
  static const maroonTintBorder = Color(0xFFE8D3E0);
  static const rowPressTint = Color(0xFFFAF5F8);

  static const onboardingGradTop = Color(0xFFFCF6EE);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  static const heroGradientDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDeep, accent],
  );
}

/// Text style helpers — 'Bricolage Grotesque' for display/headings,
/// 'Plus Jakarta Sans' for body/UI text.
class AppText {
  AppText._();

  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Bricolage Grotesque',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
    FontStyle? style,
  }) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: style,
    );
  }
}
