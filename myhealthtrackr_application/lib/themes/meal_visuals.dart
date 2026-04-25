import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';

class MealVisuals {
  static MealVisual forType(String mealType) {
    return switch (mealType) {
      'Breakfast' => const MealVisual(
        icon: AppIcons.wbSunnyOutlined,
        accent: AppColours.mealBreakfast,
      ),
      'Lunch' => const MealVisual(
        icon: AppIcons.lunchDiningOutlined,
        accent: AppColours.mealLunch,
      ),
      'Dinner' => const MealVisual(
        icon: AppIcons.dinnerDiningOutlined,
        accent: AppColours.mealDinner,
      ),
      'Water' => const MealVisual(
        icon: AppIcons.waterDropRounded,
        accent: AppColours.mealWater,
      ),
      _ => const MealVisual(
        icon: AppIcons.cookieOutlined,
        accent: AppColours.mealSnacks,
      ),
    };
  }
}

class MealVisual {
  const MealVisual({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}
