import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myhealthtrackr/services/weight_history_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

const _currentWeightAccent = AppColours.accentFat;
const _progressAccent = AppColours.accentLime;

class WeightProgressCard extends StatelessWidget {
  const WeightProgressCard({
    super.key,
    required this.entries,
    this.onLogCurrentWeight,
    this.onSelectEntry,
  });

  final List<WeightEntryData> entries;
  final VoidCallback? onLogCurrentWeight;
  final ValueChanged<WeightEntryData>? onSelectEntry;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = List<WeightEntryData>.from(entries)
      ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));

    final latestEntry = sortedEntries.isEmpty ? null : sortedEntries.last;
    final firstEntry = sortedEntries.isEmpty ? null : sortedEntries.first;
    final latestWeight = latestEntry?.weightKg;
    final firstWeight = firstEntry?.weightKg;
    final weightChange = latestWeight == null || firstWeight == null
        ? null
        : latestWeight - firstWeight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColours.accentHydration.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.monitorWeightOutlined,
                  color: AppColours.accentHydration,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Weight progress',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (sortedEntries.isEmpty)
            const _EmptyWeightProgressState()
          else ...[
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _WeightStatTile(
                      label: 'Starting weight',
                      value: '${_formatWeight(firstWeight!)} kg',
                      accent: AppColours.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WeightStatTile(
                      label: 'Current weight',
                      value: '${_formatWeight(latestWeight!)} kg',
                      accent: _currentWeightAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WeightStatTile(
                      label: 'Progress',
                      value: _formatWeightDelta(weightChange),
                      accent: _progressAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _WeightTrendChart(
              entries: sortedEntries,
              onSelectEntry: onSelectEntry,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogCurrentWeight,
              style: FilledButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                disabledBackgroundColor: AppColours.primary.withValues(
                  alpha: 0.45,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(AppIcons.monitorWeightOutlined, size: 20),
              label: const Text('Log weight'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightTrendChart extends StatefulWidget {
  const _WeightTrendChart({required this.entries, this.onSelectEntry});

  final List<WeightEntryData> entries;
  final ValueChanged<WeightEntryData>? onSelectEntry;

  @override
  State<_WeightTrendChart> createState() => _WeightTrendChartState();
}

class _WeightTrendChartState extends State<_WeightTrendChart> {
  int? _selectedEntryId;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final firstEntry = entries.first;
    final latestEntry = entries.last;
    final firstWeight = firstEntry.weightKg;
    final weights = entries
        .map((entry) => entry.weightKg)
        .toList(growable: false);

    var minWeight = weights.reduce(math.min);
    var maxWeight = weights.reduce(math.max);
    if ((maxWeight - minWeight).abs() < 0.01) {
      minWeight -= 1;
      maxWeight += 1;
    } else {
      final padding = (maxWeight - minWeight) * 0.10;
      minWeight -= padding;
      maxWeight += padding;
    }

    final baselineWeight = firstWeight;
    final midWeight = (minWeight + maxWeight) / 2;
    final selectedIndex = _selectedEntryId == null
        ? -1
        : entries.indexWhere((entry) => entry.id == _selectedEntryId);
    final selectedEntry = entries.cast<WeightEntryData?>().firstWhere(
      (entry) => entry?.id == _selectedEntryId,
      orElse: () => null,
    );
    final spots = _buildChartSpots(entries);
    final minX = entries.length == 1 ? -1.0 : 0.0;
    final maxX = entries.length == 1 ? 1.0 : (entries.length - 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: selectedEntry == null
              ? const SizedBox.shrink()
              : Material(
                  key: ValueKey<int>(selectedEntry.id),
                  color: AppColours.transparent,
                  child: InkWell(
                    onTap: widget.onSelectEntry == null
                        ? null
                        : () => widget.onSelectEntry!(selectedEntry),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColours.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColours.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.monitorWeightOutlined,
                            size: 16,
                            color: AppColours.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDate(selectedEntry.recordedAt)}  •  ${_formatWeight(selectedEntry.weightKg)} kg',
                            style: AppTextStyles.label.copyWith(
                              color: AppColours.onDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.onSelectEntry != null) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              AppIcons.editOutlined,
                              size: 16,
                              color: AppColours.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        if (selectedEntry != null) const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 260,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColours.background.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColours.dividerLight),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 62,
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '${_formatWeight(maxWeight)} kg',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColours.textSubtle,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_formatWeight(midWeight)} kg',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColours.textSubtle,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                '${_formatWeight(minWeight)} kg',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColours.textSubtle,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          minX: minX,
                          maxX: maxX,
                          minY: minWeight,
                          maxY: maxWeight,
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            drawVerticalLine: entries.length > 2,
                            horizontalInterval: (maxWeight - minWeight) / 2,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColours.dividerLight.withValues(
                                alpha: 0.6,
                              ),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (_) => FlLine(
                              color: AppColours.dividerLight.withValues(
                                alpha: 0.6,
                              ),
                              strokeWidth: 1,
                            ),
                            checkToShowVerticalLine: (value) =>
                                value > minX &&
                                value < maxX &&
                                value == value.roundToDouble(),
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: baselineWeight,
                                color: AppColours.primary.withValues(
                                  alpha: 0.45,
                                ),
                                strokeWidth: 1.4,
                              ),
                              HorizontalLine(
                                y: latestEntry.weightKg,
                                color: _currentWeightAccent.withValues(
                                  alpha: 0.55,
                                ),
                                strokeWidth: 1.4,
                              ),
                            ],
                          ),
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: false,
                            touchSpotThreshold: 28,
                            touchCallback: (event, response) {
                              if (event is! FlTapDownEvent &&
                                  event is! FlLongPressStart &&
                                  event is! FlPanUpdateEvent) {
                                return;
                              }

                              final touchedSpots = response?.lineBarSpots;
                              if (touchedSpots == null ||
                                  touchedSpots.isEmpty) {
                                setState(() => _selectedEntryId = null);
                                return;
                              }

                              final spotIndex = touchedSpots.first.spotIndex;
                              if (spotIndex < 0 ||
                                  spotIndex >= entries.length) {
                                return;
                              }

                              setState(() {
                                _selectedEntryId = entries[spotIndex].id;
                              });
                            },
                            getTouchedSpotIndicator: (_, indicators) {
                              return indicators
                                  .map((_) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: AppColours.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        strokeWidth: 1.2,
                                      ),
                                      FlDotData(
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              final isLatest =
                                                  index == entries.length - 1;
                                              return FlDotCirclePainter(
                                                radius: 5,
                                                color: isLatest
                                                    ? _currentWeightAccent
                                                    : AppColours.primary,
                                                strokeColor: AppColours.onDark,
                                                strokeWidth: 2.5,
                                              );
                                            },
                                      ),
                                    );
                                  })
                                  .toList(growable: false);
                            },
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              color: _progressAccent,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              isStrokeJoinRound: true,
                              dotData: FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  final isLatest = index == entries.length - 1;
                                  final isSelected = index == selectedIndex;
                                  return FlDotCirclePainter(
                                    radius: isSelected ? 5 : 3.5,
                                    color: isLatest
                                        ? _currentWeightAccent
                                        : AppColours.primary,
                                    strokeColor: AppColours.onDark,
                                    strokeWidth: isSelected ? 2.5 : 2,
                                  );
                                },
                              ),
                              showingIndicators: selectedIndex < 0
                                  ? const []
                                  : [selectedIndex],
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 180),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 72),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _formatDate(firstEntry.recordedAt),
                          style: AppTextStyles.label.copyWith(
                            color: AppColours.textSubtle,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(latestEntry.recordedAt),
                          style: AppTextStyles.label.copyWith(
                            color: AppColours.textSubtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<FlSpot> _buildChartSpots(List<WeightEntryData> entries) {
  return [
    for (var index = 0; index < entries.length; index++)
      FlSpot(
        entries.length == 1 ? 0 : index.toDouble(),
        entries[index].weightKg,
      ),
  ];
}

class _EmptyWeightProgressState extends StatelessWidget {
  const _EmptyWeightProgressState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'You do not have any recorded weight entries yet. Use the button below to add your first weigh-in and start building your progress timeline.',
        style: AppTextStyles.bodyMuted.copyWith(
          color: AppColours.textMuted,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _WeightStatTile extends StatelessWidget {
  const _WeightStatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColours.background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: AppColours.textSubtle,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTextStyles.title.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWeight(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String _formatWeightDelta(double? value) {
  if (value == null) return '0.0 kg';
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_formatWeight(value)} kg';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]}';
}
