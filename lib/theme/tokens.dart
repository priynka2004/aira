// FILE: theme/tokens.dart
// Design tokens: AiraColors (colours), AiraGradients, AiraText (fonts / text styles).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aira Colors.
class AiraColors {
  AiraColors._();

  static const bg = Color(0xFFFFF1F4);
  static const card = Color(0xFFFFFFFF);
  static const blush = Color(0xFFFCE3EA);
  static const rose = Color(0xFFC2185B);
  static const roseDeep = Color(0xFF8B0F38);
  static const coral = Color(0xFFE68A6C);
  static const gold = Color(0xFFC6A15B);
  static const goldSoft = Color(0xFFEFE1BE);
  static const charcoal = Color(0xFF4A1226);
  static const charcoalSoft = Color(0xFF8A6572);
  static const hair = Color(0xFFF6BFCD);
  static const success = Color(0xFF3FA36B);
  static const warn = Color(0xFFD9A441);
  static const errorBg = Color(0xFFFBEBE7);
  static const errorText = Color(0xFFC15B4A);
  static const charcoalDeep2 = Color(0xFF453832);
  static const outerBg = Color(0xFFFCE3EA);
  static const crimson = Color(0xFFC2185B);
  static const maroon = Color(0xFF8B0F38);
  static const pinkFill = Color(0xFFFFF7F9);
  static const pinkBorder = Color(0xFFF2A3B8);
}

/// Aira Gradients.
class AiraGradients {
  AiraGradients._();

  static const button = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD02A66), Color(0xFF8B0F38)],
  );

  static const page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE4EB), Color(0xFFFFF6F8), Color(0xFFFFDDE6)],
    stops: [0.0, 0.5, 1.0],
  );

  static const aira = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AiraColors.rose, AiraColors.roseDeep],
  );

  static const hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AiraColors.blush, AiraColors.bg],
  );

  static const financeCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE1E9), Color(0xFFFFF3F6)],
  );

  static const marketingPreview = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AiraColors.rose, AiraColors.gold],
  );

  static const beautyLookTile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AiraColors.blush, AiraColors.goldSoft],
  );

  static const avatarOrb = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AiraColors.rose, AiraColors.roseDeep],
  );
}

/// Aira Text.
class AiraText {
  AiraText._();

  static TextStyle serif({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AiraColors.roseDeep,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AiraColors.charcoal,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.figtree(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
