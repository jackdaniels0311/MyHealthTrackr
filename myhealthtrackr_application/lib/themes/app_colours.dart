import 'package:flutter/material.dart';

class AppColours {
  // Brand / primary
  static const Color primary = Color(0xFFCC471E);
  static const Color primaryActive = Color(0xFFC24A2A);
  static const Color primaryPressed = Color(0xFF8D3C23);

  // Surfaces
  static const Color background = Color(0xFF1D2123);
  static const Color secondary = Color(0xFF2F3134);
  static const Color surfaceTrack = Color(0xFF1B1E21);

  // Content
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF3F5F7);
  static const Color textMuted = Color(0xB3FFFFFF);
  static const Color textSubtle = Color(0xFF9AA3B2);
  static const Color textFaint = Color(0x8AFFFFFF);
  static const Color textHigh = Color(0xEBFFFFFF);

  // Semantic colours
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1C40F);
  static const Color danger = Color(0xFFE74C3C);

  // Accent colours
  static const Color accentMeal = Color(0xFFFF9F43);
  static const Color accentProtein = Color(0xFF10C98A);
  static const Color accentSleep = Color(0xFF6D8CFF);
  static const Color accentAlert = Color(0xFFFF6B6B);
  static const Color accentHydration = Color(0xFF5DA2FF);
  static const Color accentFat = Color(0xFF1FB5F4);
  static const Color accentCarbs = Color(0xFFFF971A);
  static const Color accentLime = Color(0xFF9CDE68);
  static const Color accentPink = Color(0xFFE889C4);
  static const Color accentGreen = Color(0xFF76D146);

  // Meal palette shared between Diary and Home
  static const Color mealBreakfast = accentMeal;
  static const Color mealLunch = accentProtein;
  static const Color mealDinner = accentSleep;
  static const Color mealSnacks = accentAlert;
  static const Color mealWater = accentHydration;

  // Borders / dividers
  static const Color outline = Color(0xFF3A3D41);
  static const Color panelBorder = Color(0x66CC471E);
  static const Color borderLight = Color(0x40FFFFFF);
  static const Color dividerLight = Color(0x1FFFFFFF);
  static const Color dividerLightMuted = Color(0x1AFFFFFF);
  static const Color dividerLightSubtle = Color(0x14FFFFFF);

  // Inputs / overlays
  static const Color inputFill = Color(0xFF26292B);
  static const Color transparent = Color(0x00000000);
  static const Color overlayLight = Color(0x42000000);
  static const Color overlayDark = Color(0x8A000000);
  static const Color shadowSoft = Color(0x20000000);
  static const Color shadowMedium = Color(0x22000000);
  static const Color shadowStrong = Color(0x25000000);
  static const Color shadowPanel = Color(0x2B000000);
  static const Color shadowHeavy = Color(0x30000000);
}
