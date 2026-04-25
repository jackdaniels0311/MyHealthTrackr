import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

class CalorieBreakdownCard extends StatelessWidget {
  const CalorieBreakdownCard({
    required this.title,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.segments,
    required this.stats,
    this.helperText,
    super.key,
  });

  final String title;
  final double caloriesConsumed;
  final double? calorieGoal;
  final List<CalorieBreakdownSegment> segments;
  final List<CalorieBreakdownStat> stats;
  final String? helperText;

  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;

  @override
  Widget build(BuildContext context) {
    final double barDenominator = calorieGoal == null
        ? caloriesConsumed
        : math.max(calorieGoal!, caloriesConsumed).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowHeavy,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: AppTextStyles.headline.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: caloriesConsumed.toStringAsFixed(0)),
                if (calorieGoal != null)
                  TextSpan(
                    text: ' / ${calorieGoal!.toStringAsFixed(0)} kcal',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: _mutedText,
                    ),
                  )
                else
                  TextSpan(
                    text: ' kcal logged',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _mutedText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SegmentedBar(
            segments: [
              for (final segment in segments)
                _CardBarSegment(
                  value: barDenominator <= 0
                      ? 0
                      : segment.calories / barDenominator,
                  colour: segment.colour,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final segment in segments)
                _LegendItem(
                  label: segment.label,
                  value: '${_formatMetric(segment.calories)} kcal',
                  colour: segment.colour,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColours.background.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                for (final stat in stats)
                  Expanded(
                    child: _SnapshotStat(label: stat.label, value: stat.value),
                  ),
              ],
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 16),
            Text(
              helperText!,
              style: AppTextStyles.bodyMuted.copyWith(
                color: _mutedText,
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

class CalorieBreakdownSegment {
  const CalorieBreakdownSegment({
    required this.label,
    required this.calories,
    required this.colour,
  });

  final String label;
  final double calories;
  final Color colour;
}

class CalorieBreakdownStat {
  const CalorieBreakdownStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _CardBarSegment {
  const _CardBarSegment({required this.value, required this.colour});

  final double value;
  final Color colour;
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.segments});

  final List<_CardBarSegment> segments;

  @override
  Widget build(BuildContext context) {
    final visibleSegments = segments
        .where((segment) => segment.value > 0)
        .toList(growable: false);
    final used = visibleSegments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 18,
        child: Stack(
          children: [
            Container(color: AppColours.surfaceTrack),
            if (visibleSegments.isNotEmpty)
              Row(
                children: [
                  for (final segment in visibleSegments)
                    Flexible(
                      flex: math.max(1, (segment.value * 1000).round()),
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

class _SnapshotStat extends StatelessWidget {
  const _SnapshotStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColours.textSubtle,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedValue,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String get _formattedValue {
    if (label != 'Remaining') {
      return value;
    }

    final match = RegExp(r'^(-?\d+(?:\.\d+)?)(.*)$').firstMatch(value.trim());
    if (match == null) {
      return value;
    }

    final numericValue = double.tryParse(match.group(1) ?? '');
    if (numericValue == null) {
      return value;
    }

    final suffix = match.group(2) ?? '';
    return '${numericValue.round()}$suffix';
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.colour,
  });

  final String label;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textSubtle,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
