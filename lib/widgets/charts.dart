import 'package:dhealth/database/database.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/settings_model.dart';
import 'package:dhealth/utils/chart_range.dart';
import 'package:dhealth/utils/step_calculator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// 圖表群。公開四個元件：[HourlyStepsChart]、[DailyStepsChart]、[WeeklyStepsChart]、
/// [MonthlyStepsChart]。
///
/// 三張期圖（日/週/月）共用同一個 `getAllDailySteps()` future（由 HomeScreen 建立、
/// 同步 token 變動時重抓）—— 以前每張圖各自查全表，每次刷新讀三遍。
/// 日/週/月的資料是「補零」的：0 步的天/週/月在 DB 沒有列，不補的話「最近 N 期」
/// 會變成「最近 N 個有步數的期」，平均高估（見 `StepCalculator`）。

/// 今天每小時的步數曲線。[totals] 是今天每個小時的步數（由 HomeScreen 同步後取得，已在 Health Connect 去重）。
///
/// [totals] = null 代表「今天根本沒讀到」（Health Connect 失靈/無權限），
/// 那種情況要明講，不能畫一條 0 步的線 —— 那會看起來像「今天一步都沒走」。
class HourlyStepsChart extends StatelessWidget {
  const HourlyStepsChart({super.key, required this.totals, this.loading = false});

  final Map<int, int>? totals;

  /// 還在第一次查詢中（尚無結果）。
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hourly = totals;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hourly == null) {
      return _EmptyCard(message: l10n.hourlyDataUnavailable);
    }
    final settings = Provider.of<SettingsModel>(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    final display = Map<int, int>.from(hourly);
    var cumulative = 0;
    if (settings.showCumulative) {
      for (var i = 0; i < 24; i++) {
        cumulative += hourly[i] ?? 0;
        display[i] = cumulative;
      }
    }

    final totalSteps = settings.showCumulative ? (display[23] ?? 0) : hourly.values.fold(0, (a, b) => a + b);
    final maxValue = display.values.fold(0, (max, value) => value > max ? value : max);
    final chartMaxY = maxValue > 0
        ? (settings.showDailyStepGoal && settings.dailyStepGoal > maxValue ? settings.dailyStepGoal * 1.3 : maxValue * 1.3)
        : 10.0;
    final lineColor = _getTimeBasedColor(now.hour);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    '${l10n.today}: $totalSteps ${l10n.steps}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _HelpButton(explanation: l10n.hourlyStepsChartExplanation),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      maxY: chartMaxY,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(24, (hour) => FlSpot(hour.toDouble(), (display[hour] ?? 0).toDouble())),
                          isCurved: true,
                          color: lineColor, // 曲線是單一段落，用「現在幾點」的色系保持一致
                          barWidth: 2,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: .2)),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value >= chartMaxY * 0.95) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final hour = value.toInt();
                              if (hour % 3 != 0) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '$hour:00',
                                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                              );
                            },
                            reservedSize: 24,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.15), width: 1),
                          left: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.15), width: 1),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), strokeWidth: 1, dashArray: const [4, 4]),
                      ),
                      extraLinesData: settings.showDailyStepGoal
                          ? ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: settings.dailyStepGoal.toDouble(),
                                  color: Colors.red.withValues(alpha: 0.7),
                                  strokeWidth: 2,
                                  dashArray: const [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                    labelResolver: (_) => '${l10n.goalShort}: ${settings.dailyStepGoal}',
                                  ),
                                ),
                              ],
                            )
                          : null,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.blueGrey[700]!,
                          getTooltipItems: (touchedSpots) => touchedSpots
                              .map((spot) => LineTooltipItem(
                                  l10n.hourSteps(spot.x.toInt(), spot.y.toInt()),
                                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniSwitch(
                          label: l10n.cumulativeShort,
                          value: settings.showCumulative,
                          onChanged: settings.setShowCumulative,
                        ),
                        const SizedBox(height: 20),
                        _MiniSwitch(label: l10n.goalShort, value: settings.showDailyStepGoal, onChanged: settings.setShowDailyStepGoal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 區間內每一天。
class DailyStepsChart extends StatelessWidget {
  const DailyStepsChart({super.key, required this.steps, required this.range});

  /// 三張期圖共用的全表 future（由 HomeScreen 建立、同步 token 變動時重抓）。
  final Future<List<DailyStep>> steps;
  final ChartRange range;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return _StepChart(
      steps: steps,
      range: range,
      plan: (r) => r.days(),
      group: StepCalculator.calculateDailySteps,
      titlePrefix: AppLocalizations.of(context)!.days,
      barWidth: 10,
      showDayOfWeek: true,
      bottomTitleFormat: (date) => DateFormat('M/d', locale).format(date),
    );
  }
}

/// 區間涵蓋的每一週（對齊到週一）。
class WeeklyStepsChart extends StatelessWidget {
  const WeeklyStepsChart({super.key, required this.steps, required this.range});

  final Future<List<DailyStep>> steps;
  final ChartRange range;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return _StepChart(
      steps: steps,
      range: range,
      plan: (r) => r.weeks(),
      group: StepCalculator.calculateWeeklySteps,
      titlePrefix: AppLocalizations.of(context)!.weeks,
      barWidth: 20,
      showDayOfWeek: false,
      bottomTitleFormat: (date) => DateFormat('M/d', locale).format(date),
    );
  }
}

/// 區間涵蓋的每一月（對齊到月初）。
class MonthlyStepsChart extends StatelessWidget {
  const MonthlyStepsChart({super.key, required this.steps, required this.range});

  final Future<List<DailyStep>> steps;
  final ChartRange range;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return _StepChart(
      steps: steps,
      range: range,
      plan: (r) => r.months(),
      group: StepCalculator.calculateMonthlySteps,
      titlePrefix: AppLocalizations.of(context)!.months,
      barWidth: 30,
      showDayOfWeek: false,
      bottomTitleFormat: (date) => DateFormat('yyyy-MM', locale).format(date),
    );
  }
}

/// 只保留日期落在 [from]～[to]（含）的紀錄。
List<DailyStep> _within(List<DailyStep> steps, DateTime from, DateTime to) {
  return steps.where((step) {
    final date = DateTime.tryParse(step.date);
    return date != null && !date.isBefore(from) && !date.isAfter(to);
  }).toList();
}

class _StepChart extends StatelessWidget {
  const _StepChart({
    required this.steps,
    required this.range,
    required this.plan,
    required this.group,
    required this.titlePrefix,
    required this.barWidth,
    required this.showDayOfWeek,
    required this.bottomTitleFormat,
  });

  final Future<List<DailyStep>> steps;
  final ChartRange range;

  /// 由期數與頁碼算出這個週期的起訖與期數。
  final ({DateTime from, DateTime to, int periods}) Function(ChartRange) plan;
  final List<DailyStep> Function(List<DailyStep>, DateTime, int) group;
  final String titlePrefix;
  final double barWidth;
  final bool showDayOfWeek;
  final String Function(DateTime) bottomTitleFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<DailyStep>>(
      future: steps,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.chartError('${snapshot.error}')));
        }

        final all = snapshot.data ?? const <DailyStep>[];
        if (all.isEmpty) return _EmptyCard(message: l10n.noDataInDatabase);

        final currentPlan = plan(range);
        final inRange = _within(all, currentPlan.from, currentPlan.to);
        // 區間內一列都沒有 → 「資料庫沒有資料」；有資料但某些天/週/月是 0 步
        // （DB 不存 0 步的列）→ group 會補零，不能當成「沒有資料」。
        if (inRange.isEmpty) return _EmptyCard(message: l10n.noDataInDatabase);
        final processed = group(inRange, currentPlan.from, currentPlan.periods);

        final prevRange = range.previous;
        final prevPlan = plan(prevRange);
        final prevProcessed = group(_within(all, prevPlan.from, prevPlan.to), prevPlan.from, prevPlan.periods);

        final currentAvg = StepCalculator.calculateAverageSteps(processed);
        final prevAvg = StepCalculator.calculateAverageSteps(prevProcessed);
        final percentageDiff = prevAvg != 0 ? (((currentAvg - prevAvg) / prevAvg) * 100).toInt() : 0;
        final percentageString = percentageDiff >= 0 ? '+$percentageDiff%' : '$percentageDiff%';
        final prefix = '${l10n.past} ';

        return _BarChart(
          periodSteps: processed,
          periods: currentPlan.periods,
          title:
              '$prefix${currentPlan.periods} $titlePrefix: ${l10n.average} ${NumberFormat.decimalPattern().format(currentAvg.toInt())} ${l10n.steps} ($percentageString)',
          barWidth: barWidth,
          showDayOfWeek: showDayOfWeek,
          averageSteps: currentAvg,
          bottomTitleFormat: bottomTitleFormat,
        );
      },
    );
  }
}

/// 首頁圖表的期數選擇：7／30／90 期，‹ › 翻頁（圖表區也能左右滑）。
class ChartRangeSelector extends StatelessWidget {
  const ChartRangeSelector({super.key, required this.range, required this.onPeriods, required this.onOffset});

  final ChartRange range;
  final ValueChanged<int> onPeriods;
  final ValueChanged<int> onOffset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: l10n.previousPage,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onOffset(range.offset + 1),
          ),
          for (final periods in ChartRange.presets)
            ChoiceChip(
              label: Text('$periods ${l10n.periods}'),
              selected: range.periods == periods,
              onSelected: (_) => onPeriods(periods),
            ),
          IconButton(
            tooltip: l10n.nextPage,
            icon: const Icon(Icons.chevron_right),
            onPressed: range.offset > 0 ? () => onOffset(range.offset - 1) : null,
          ),
          if (range.offset > 0) TextButton(onPressed: () => onOffset(0), child: Text(l10n.latest)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.periodSteps,
    required this.periods,
    required this.title,
    required this.barWidth,
    required this.showDayOfWeek,
    required this.averageSteps,
    required this.bottomTitleFormat,
  });

  final List<DailyStep> periodSteps;
  final int periods;
  final String title;
  final double barWidth;
  final bool showDayOfWeek;
  final double averageSteps;
  final String Function(DateTime) bottomTitleFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final gridColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15);
    final averageLineColor = Colors.grey.shade700; // 深一點的灰，暗色模式下才看得清楚

    final sorted = periodSteps.map((step) => MapEntry(DateTime.parse(step.date), step.stepCount)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final visible = sorted.length > periods ? sorted.sublist(sorted.length - periods) : sorted;
    final maxValue = visible.fold(0, (max, e) => e.value > max ? e.value : max);
    final maxY = maxValue > 0 ? maxValue * 1.3 : 1000.0;
    // 柱子太多時縮窄，標籤也每隔幾根才顯示一個，避免擠在一起。
    final availableWidth = MediaQuery.sizeOf(context).width - 48;
    final rodWidth = (availableWidth / visible.length * 0.6).clamp(2.0, barWidth).toDouble();
    final labelEvery = (visible.length / 7).ceil();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 8.0, 16.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        minY: 0,
                        barGroups: List.generate(visible.length, (index) {
                          final steps = visible[index].value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: steps.toDouble(),
                                color: _getStepBasedColor(steps, maxValue, visible[index].key.weekday),
                                width: rodWidth,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= visible.length || index % labelEvery != 0) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    bottomTitleFormat(visible[index].key),
                                    style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
                                  ),
                                );
                              },
                              reservedSize: periods <= 7 ? 40 : 30,
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(bottom: BorderSide(color: gridColor, width: 1), left: BorderSide(color: gridColor, width: 1)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
                          getDrawingHorizontalLine: (value) =>
                              FlLine(color: gridColor, strokeWidth: 1, dashArray: const [4, 4]),
                        ),
                        extraLinesData: averageSteps > 0
                            ? ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: averageSteps,
                                    color: averageLineColor.withValues(alpha: 0.8),
                                    strokeWidth: 3,
                                    dashArray: const [8, 4],
                                  ),
                                ],
                              )
                            : null,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => isDark ? Colors.grey[800]! : Colors.blueGrey[700]!,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final date = visible[group.x].key;
                              final steps = rod.toY.toInt();
                              final pattern = showDayOfWeek ? 'M/d E' : 'M/d';
                              return BarTooltipItem(
                                '${DateFormat(pattern, Localizations.localeOf(context).languageCode).format(date)}\n$steps ${l10n.steps}',
                                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                children: averageSteps > 0
                                    ? [
                                        TextSpan(
                                          text: '\n${(rod.toY / averageSteps * 100).toStringAsFixed(1)}% ${l10n.percentOfAverage}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                                        ),
                                      ]
                                    : const [],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(right: 8, top: 8, child: _HelpButton(explanation: l10n.chartHelpContent)),
          ],
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chartHelpTitle),
          content: Text(explanation),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        children: [
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Colors.grey.withValues(alpha: 0.5),
              activeThumbColor: Colors.grey[600],
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

/// 依「相對最高那天」的比例挑色；週末用不同色系，一眼分得出平日/假日。
Color _getStepBasedColor(int steps, int maxSteps, int weekday) {
  final ratio = maxSteps > 0 ? steps / maxSteps : 0.0;
  final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
  final baseColor = switch (weekday) {
    DateTime.saturday => Colors.green,
    DateTime.sunday => Colors.purple,
    _ => Colors.blue,
  };

  if (ratio <= 0.1) return baseColor.shade100.withValues(alpha: 0.3);
  if (ratio <= 0.3) return Colors.cyan.shade600;
  if (ratio <= 0.5) return Colors.blue.shade300;
  if (ratio <= 0.7) return Colors.green.shade300;
  if (ratio <= 0.9) return Colors.teal.shade300;
  return isWeekend ? baseColor.shade400 : Colors.cyan.shade300;
}

/// 依時段換曲線顏色（早上偏青、中午偏藍、下午偏綠、晚上偏青綠）。
Color _getTimeBasedColor(int hour) {
  if (hour < 6) return Colors.cyan.shade300;
  if (hour < 12) return Colors.blue.shade300;
  if (hour < 18) return Colors.green.shade400;
  return Colors.teal.shade300;
}
