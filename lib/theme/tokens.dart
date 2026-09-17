import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — ported 1:1 from the AiRA React prototype (`const C = {...}`).
class AiraColors {
  AiraColors._();

  static const bg = Color(0xFFFDF9F6);
  static const card = Color(0xFFFFFFFF);
  static const blush = Color(0xFFF6DEE3);
  static const rose = Color(0xFFC36E86);
  static const roseDeep = Color(0xFFA85770);
  static const coral = Color(0xFFE68A6C);
  static const gold = Color(0xFFC6A15B);
  static const goldSoft = Color(0xFFEFE1BE);
  static const charcoal = Color(0xFF2C2320);
  static const charcoalSoft = Color(0xFF6B5F5A);
  static const hair = Color(0xFFEFE6E1);
  static const success = Color(0xFF6E9B7A);
  static const warn = Color(0xFFD9A441);
  static const errorBg = Color(0xFFFBEBE7);
  static const errorText = Color(0xFFC15B4A);
  static const charcoalDeep2 = Color(0xFF453832); // finance card gradient end
  static const outerBg = Color(0xFFEFE9E4);
}

class AiraGradients {
  AiraGradients._();

  static const aira = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AiraColors.rose, AiraColors.gold],
  );

  static const hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AiraColors.blush, AiraColors.bg],
  );

  static const financeCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AiraColors.charcoal, AiraColors.charcoalDeep2],
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
    colors: [AiraColors.rose, AiraColors.gold],
  );
}

/// `serif` (Fraunces) and `sans` (Inter) text style helpers.
class AiraText {
  AiraText._();

  static TextStyle serif({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AiraColors.charcoal,
    double? height,
  }) =>
      GoogleFonts.fraunces(
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
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
