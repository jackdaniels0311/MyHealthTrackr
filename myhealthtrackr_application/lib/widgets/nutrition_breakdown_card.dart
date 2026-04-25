import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

class NutritionBreakdownCard extends StatelessWidget {
  const NutritionBreakdownCard({
    required this.protein,
    required this.carbs,
    required this.fat,
    this.calories,
    super.key,
  });

  final double? protein;
  final double? carbs;
  final double? fat;
  final double? calories;

  @override
  Widget build(BuildContext context) {
    final segments = <_MacroSegment>[
      _MacroSegment(
        label: 'Protein',
        grams: protein ?? 0,
        colour: AppColours.accentProtein,
      ),
      _MacroSegment(
        label: 'Carbs',
        grams: carbs ?? 0,
        colour: AppColours.accentCarbs,
      ),
      _MacroSegment(
        label: 'Fat',
        grams: fat ?? 0,
        colour: AppColours.accentFat,
      ),
    ];
    final totalGrams = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.grams,
    );
    final caloriesLabel = FoodService.formatCalories(calories);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColours.dividerLightMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Macro breakdown',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                caloriesLabel,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColours.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (totalGrams > 0) ...[
            _MacroSegmentedBar(segments: segments, totalGrams: totalGrams),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final segment in segments)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: segment == segments.last ? 0 : 10,
                      ),
                      child: _MacroLegendItem(
                        label: segment.label,
                        grams: segment.grams,
                        percentage: totalGrams <= 0
                            ? 0
                            : (segment.grams / totalGrams) * 100,
                        colour: segment.colour,
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            Text(
              'Macro values will appear here once nutrition information is available.',
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatMetric(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _MacroSegment {
  const _MacroSegment({
    required this.label,
    required this.grams,
    required this.colour,
  });

  final String label;
  final double grams;
  final Color colour;
}

class _MacroSegmentedBar extends StatelessWidget {
  const _MacroSegmentedBar({required this.segments, required this.totalGrams});

  final List<_MacroSegment> segments;
  final double totalGrams;

  @override
  Widget build(BuildContext context) {
    final visibleSegments = segments
        .where((segment) => segment.grams > 0)
        .toList(growable: false);
    final used = visibleSegments.fold<double>(
      0,
      (sum, segment) => sum + (segment.grams / totalGrams),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 16,
        child: Stack(
          children: [
            Container(color: AppColours.surfaceTrack),
            if (visibleSegments.isNotEmpty)
              Row(
                children: [
                  for (final segment in visibleSegments)
                    Flexible(
                      flex: math.max(
                        1,
                        ((segment.grams / totalGrams) * 1000).round(),
                      ),
                      child: Container(color: segment.colour),
                    ),
                  if (used < 1)
                    Flexible(
                      flex: math.max(
                        1,
                        ((1 - used).clamp(0.0, 1.0) * 1000).round(),
                      ),
                      child: Container(color: AppColours.transparent),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  const _MacroLegendItem({
    required this.label,
    required this.grams,
    required this.percentage,
    required this.colour,
  });

  final String label;
  final double grams;
  final double percentage;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColours.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${NutritionBreakdownCard._formatMetric(grams)}g',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.round()}%',
            style: AppTextStyles.bodyMuted.copyWith(
              color: colour,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
