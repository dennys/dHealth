import 'dart:async';

import 'package:dsteps/database/database.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:dsteps/settings_model.dart';
import 'package:dsteps/utils/step_calculator.dart';
import 'package:dsteps/utils/weekday_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
/*
for chart
1. I cannot see the horizontal average line, change the color to bold dotted line with grey color.
2. refresh data when I pull down the screen
3. In buildLastNDays(Week/Month)Chart, if users swipe left, load all history data and show it on screen.
users can swipe right again to see newer data.
4. Is this a good design? will it make screen flash or ???
5. Why database doesn't provide a API to get ranged data?

Hourly chart
1. It refresh all screen when change cumulative
*/

enum ChartType { daily, weekly, monthly }

// Helper class to hold chart data
class ChartData {
  final List<dynamic> dataset;
  final int average;
  final int displayRange;

  ChartData(this.dataset, this.average, this.displayRange);
}

Widget _buildBarChart2(
  BuildContext context,
  List<dynamic> dataset,
  ChartType dataType,
  String title,
  int average,
  int displayRange,
  double barWidth,
) {
  final theme = Theme.of(context);
  final localizations = AppLocalizations.of(context)!;
  final isDarkTheme = theme.brightness == Brightness.dark;

  final sortedData = dataset..sort((a, b) => (a[0] as DateTime).compareTo(b[0] as DateTime));
  int startIndex = sortedData.length > displayRange ? sortedData.length - displayRange : 0;

  bool showAverageLine = true;

  String formatDate(DateTime date) {
    switch (dataType) {
      case ChartType.daily:
        return DateFormat.EEEE(localizations.localeName).format(date);
      case ChartType.weekly:
        return DateFormat('M/d', localizations.localeName).format(date);
      case ChartType.monthly:
        return DateFormat.MMM(localizations.localeName).format(date);
    }
  }

  List<dynamic> getVisibleData(List<dynamic> sortedData) {
    if (sortedData.isEmpty) return [];
    final endIndex = (startIndex + displayRange).clamp(0, sortedData.length);
    return sortedData.sublist(startIndex, endIndex);
  }

  // List<dynamic> displayData = sortedData.length > displayRange ? sortedData.sublist(sortedData.length - displayRange) : sortedData;
  late List<dynamic> displayData = getVisibleData(sortedData);

  void handleSwipe(double velocity) {
    showAverageLine = false;
    final sortedData = dataset;
    final direction = velocity > 0 ? -1 : 1; // Left swipe: +1, Right swipe: -1
    final newStartIndex = (startIndex + direction * displayRange).clamp(0, sortedData.length - displayRange);

    if (newStartIndex != startIndex) {
      startIndex = newStartIndex;
      displayData = getVisibleData(sortedData);
    }
  }

  return GestureDetector(
    // onHorizontalDragUpdate: (details) {
    onHorizontalDragEnd: (details) {
      handleSwipe(details.primaryVelocity ?? 0);
      // showAverageLine = false;
    },
    child: Stack(
      children: [
        BarChart(
          BarChartData(
            // ... (rest of BarChartData remains the same)
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                // tooltipBgColor: isDarkTheme ? Colors.grey[800]! : Colors.grey[200]!,
                getTooltipColor: (_) => isDarkTheme ? Colors.grey[800]! : Colors.blueGrey[700]!,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final date = displayData[group.x.toInt()][0] as DateTime;
                  final count = rod.toY.toInt();
                  final delta = count - average;
                  return BarTooltipItem(
                    '${formatDate(date)}\n$count\n${delta >= 0 ? '+' : ''}$delta',
                    TextStyle(color: isDarkTheme ? Colors.white : Colors.black, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < displayData.length) {
                      // return Text(formatDate(displayData[index][0]), style: theme.textTheme.caption);
                      return Text(formatDate(displayData[index][0]), style: theme.textTheme.titleMedium);
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
            borderData: FlBorderData(show: false),
            barGroups:
                displayData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [BarChartRodData(toY: data[1].toDouble(), width: barWidth, color: theme.colorScheme.primary)],
                  );
                }).toList(),
            extraLinesData:
                showAverageLine
                    ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: average.toDouble(),
                          color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                      ],
                    )
                    : null,
          ),
        ),
        // Positioned(top: 8, left: 8, child: Text(title, style: theme.textTheme.subtitle1)),
        Positioned(top: 8, left: 8, child: Text(title, style: theme.textTheme.titleSmall)),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: Icon(Icons.help_outline, color: isDarkTheme ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7)),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(localizations.chartHelpTitle),
                      content: Text(localizations.chartHelpContent),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.ok))],
                    ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildBarChart({
  required BuildContext context,
  required List<DailyStep> periodSteps,
  required int periods,
  required String title,
  required double barWidth,
  required bool showDayOfWeek,
  required double averageSteps,
  required String Function(DateTime) bottomTitleFormat,
}) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  final ThemeData theme = Theme.of(context);
  final bool isDark = theme.brightness == Brightness.dark;
  final Color textColor = isDark ? Colors.white : Colors.black;
  final Color gridColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15);
  final Color averageLineColor = Colors.grey.shade700; // Darker grey for better visibility

  List<MapEntry<DateTime, int>> sortedPeriods =
      periodSteps.map((step) => MapEntry(DateTime.parse(step.date), step.stepCount)).toList()..sort((a, b) => a.key.compareTo(b.key));

  if (sortedPeriods.length > periods) {
    sortedPeriods = sortedPeriods.sublist(sortedPeriods.length - periods);
  }

  final int maxValue = sortedPeriods.isEmpty ? 0 : sortedPeriods.map((e) => e.value).reduce((max, value) => max > value ? max : value);

  if (sortedPeriods.isEmpty) {
    return Padding(padding: const EdgeInsets.all(16.0), child: Text('No data available', style: TextStyle(fontSize: 14, color: textColor)));
  }

  return SizedBox(
    height: 300,
    child: Card(
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
                        maxY: maxValue * 1.3,
                        minY: 0,
                        barGroups: List.generate(sortedPeriods.length, (index) {
                          final int steps = sortedPeriods[index].value;
                          final int weekday = sortedPeriods[index].key.weekday;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: steps.toDouble(),
                                color: _getStepBasedColor(steps, maxValue, weekday),
                                width: barWidth,
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
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7))),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final int index = value.toInt();
                                if (index >= 0 && index < sortedPeriods.length) {
                                  final DateTime date = sortedPeriods[index].key;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(bottomTitleFormat(date), style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7))),
                                  );
                                }
                                return const SizedBox();
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
                          horizontalInterval: maxValue > 0 ? maxValue * 1.3 / 4 : 1000,
                          getDrawingHorizontalLine: (value) {
                            if (value == averageSteps) {
                              return FlLine(color: averageLineColor.withValues(alpha: 0.8), strokeWidth: 3, dashArray: [8, 4]);
                            }
                            return FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]);
                          },
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => isDark ? Colors.grey[800]! : Colors.blueGrey[700]!,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final DateTime date = sortedPeriods[group.x].key;
                              final int steps = rod.toY.toInt();
                              return BarTooltipItem(
                                '${DateFormat(showDayOfWeek ? 'M/d E' : 'M/d', Localizations.localeOf(context).languageCode).format(date)}\n$steps ${localizations.steps}',
                                TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                children: [
                                  TextSpan(
                                    text: '\n${(rod.toY / averageSteps * 100).toStringAsFixed(1)}% of avg',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                                  ),
                                ],
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
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: Icon(Icons.help_outline, color: textColor.withValues(alpha: 0.3)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(localizations.chartHelpTitle),
                          content: Text(localizations.chartHelpContent),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.ok))],
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildStepChart({
  required BuildContext context,
  required StepDatabase database,
  required int periods,
  required String titlePrefix,
  required double barWidth,
  required bool showDayOfWeek,
  required List<DailyStep> Function(List<DailyStep>) processSteps,
  required int Function(List<DailyStep>) getCurrentValue,
  required double Function(List<DailyStep>) getAverage,
  required double Function(List<DailyStep>) getPreviousAverage,
  required String Function(DateTime) bottomTitleFormat,
}) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  return RefreshIndicator(
    onRefresh: () async {
      await database.getAllDailySteps();
    },
    child: FutureBuilder<List<DailyStep>>(
      future: database.getAllDailySteps(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
        }

        final List<DailyStep> processedSteps = processSteps(snapshot.data!);
        final double currentAvg = getAverage(processedSteps);
        final double prevAvg = getPreviousAverage(snapshot.data!);
        final int percentageDiff = prevAvg != 0 ? (((currentAvg - prevAvg) / prevAvg) * 100).toInt() : 0;
        final String percentageString = percentageDiff >= 0 ? '+$percentageDiff%' : '$percentageDiff%';

        return _buildBarChart(
          context: context,
          periodSteps: processedSteps,
          periods: periods,
          title:
              '${localizations.past} $periods $titlePrefix: ${localizations.average} ${NumberFormat.decimalPattern().format(currentAvg.toInt())} ${localizations.steps} ($percentageString)',
          barWidth: barWidth,
          showDayOfWeek: showDayOfWeek,
          averageSteps: currentAvg,
          bottomTitleFormat: bottomTitleFormat,
        );
      },
    ),
  );
}

// Data Fetching with Error Handling
Future<ChartData> _fetchChartData({
  required StepDatabase database,
  required int n,
  required ChartType dataType,
  required String rangeKey,
  required int defaultRange,
  DateTime? endDate,
}) async {
  try {
    final now = endDate ?? DateTime.now();
    late DateTime startDate;

    switch (dataType) {
      case ChartType.daily:
        startDate = now.subtract(Duration(days: n));
        break;
      case ChartType.weekly:
        final weekStart = await WeekdayUtils.getWeekStartDay();
        final daysToSubtract = (weekStart == Weekday.sunday ? 7 : 6) * (n - 1);
        startDate = now.subtract(Duration(days: daysToSubtract));
        break;
      case ChartType.monthly:
        startDate = DateTime(now.year, now.month - (n - 1), 1);
        break;
    }

    late List<dynamic> dataset;
    switch (dataType) {
      case ChartType.daily:
        dataset = await database.getAllDailySteps().timeout(Duration(seconds: 10));
        break;
      case ChartType.weekly:
        dataset = await database.getAllWeeklySteps(startDate, now).timeout(Duration(seconds: 10));
        break;
      case ChartType.monthly:
        dataset = await database.getAllMonthlySteps(startDate, now).timeout(Duration(seconds: 10));
        break;
    }

    final average = await database.getDailyAverageSteps(startDate, now).timeout(Duration(seconds: 10));
    final prefs = SharedPreferencesAsync();
    final displayRange = await prefs.getInt(rangeKey) ?? defaultRange;

    return ChartData(dataset, average, displayRange);
  } on Exception catch (e) {
    throw Exception('Unexpected error: $e');
  }
}

// Daily Chart Implementation
Future<ChartData> _fetchDailyChartData(StepDatabase database, {int n = 7}) async {
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: n));

  final dataset = await database.getAllDailySteps();
  final average = await database.getDailyAverageSteps(startDate, endDate);
  final prefs = SharedPreferencesAsync();
  final displayRange = await prefs.getInt('dailyChartRange') ?? 7;

  return ChartData(dataset, average, displayRange);
}

Widget buildLastNDaysChart2(BuildContext context, StepDatabase database, {int n = 7}) {
  late Future<ChartData> chartDataFuture = _fetchDailyChartData(database, n: n);

  return FutureBuilder<ChartData>(
    future: chartDataFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      final chartData = snapshot.data!;
      return _buildBarChart2(
        context,
        chartData.dataset,
        ChartType.daily,
        AppLocalizations.of(context)!.chartTitle(n, chartData.average),
        chartData.average,
        chartData.displayRange,
        30,
      );
    },
  );
}

Widget buildLastNDaysChart(BuildContext context, StepDatabase database, {int n = 7}) {
  final DateTime today = DateTime.now();
  final DateTime startDate = today.subtract(Duration(days: n - 1));
  final DateTime prevStartDate = startDate.subtract(Duration(days: n));

  return _buildStepChart(
    context: context,
    database: database,
    periods: n,
    titlePrefix: AppLocalizations.of(context)!.days,
    barWidth: 10,
    showDayOfWeek: true,
    processSteps: (steps) => StepCalculator.calculateDailySteps(steps, startDate, n),
    getCurrentValue: (steps) => steps.last.stepCount,
    getAverage: StepCalculator.calculateAverageSteps,

    // getPreviousAverage: (prevSteps) {
    //   final prevSteps = StepCalculator.calculateDailySteps(prevSteps, prevStartDate, n);
    //   return StepCalculator.calculateAverageSteps(prevSteps);
    // },
    getPreviousAverage: (steps) {
      final filteredPrevSteps =
          steps
              .where(
                (step) =>
                    DateTime.parse(step.date).isAfter(prevStartDate.subtract(const Duration(days: 1))) &&
                    DateTime.parse(step.date).isBefore(startDate),
              )
              .toList();
      final prevSteps = StepCalculator.calculateDailySteps(filteredPrevSteps, prevStartDate, n);
      return StepCalculator.calculateAverageSteps(prevSteps);
    },
    bottomTitleFormat: (date) => DateFormat('M/d', Localizations.localeOf(context).languageCode).format(date),
  );
}

// Weekly Chart Implementation
Future<ChartData> _fetchWeeklyChartData(StepDatabase database, {int n = 7}) async {
  final endDate = DateTime.now();
  final weekStart = await WeekdayUtils.getWeekStartDay();
  final daysToSubtract = (weekStart == Weekday.sunday ? 7 : 6) * (n - 1);
  final startDate = endDate.subtract(Duration(days: daysToSubtract));

  final dataset = await database.getAllWeeklySteps(startDate, endDate);
  final average = await database.getDailyAverageSteps(startDate, endDate);
  final prefs = SharedPreferencesAsync();
  final displayRange = await prefs.getInt('weeklyChartRange') ?? 4;

  return ChartData(dataset, average, displayRange);
}

Widget buildLastNWeeksChart2(BuildContext context, StepDatabase database, {int n = 7}) {
  late Future<ChartData> chartDataFuture = _fetchWeeklyChartData(database, n: n);

  return FutureBuilder<ChartData>(
    future: chartDataFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      final chartData = snapshot.data!;
      return _buildBarChart2(
        context,
        chartData.dataset,
        ChartType.weekly,
        AppLocalizations.of(context)!.chartTitle(n, chartData.average),
        chartData.average,
        chartData.displayRange,
        30,
      );
    },
  );
}

Widget buildLastNWeeksChart(BuildContext context, StepDatabase database, {int n = 7}) {
  final DateTime today = DateTime.now();
  final DateTime startDate = today.subtract(Duration(days: (n * 7) - 1));
  final DateTime prevStartDate = startDate.subtract(Duration(days: n * 7));

  return _buildStepChart(
    context: context,
    database: database,
    periods: n,
    titlePrefix: AppLocalizations.of(context)!.weeks,
    barWidth: 20,
    showDayOfWeek: false,
    processSteps: (steps) => StepCalculator.calculateWeeklySteps(steps, startDate, n),
    getCurrentValue: (steps) => steps.last.stepCount,
    getAverage: StepCalculator.calculateAverageSteps,
    // getPreviousAverage: (steps) {
    //   final prevSteps = StepCalculator.calculateWeeklySteps(steps, prevStartDate, n);
    //   return StepCalculator.calculateAverageSteps(prevSteps);
    // },
    getPreviousAverage: (steps) {
      final filteredPrevSteps =
          steps
              .where(
                (step) =>
                    DateTime.parse(step.date).isAfter(prevStartDate.subtract(const Duration(days: 1))) &&
                    DateTime.parse(step.date).isBefore(startDate),
              )
              .toList();
      final prevSteps = StepCalculator.calculateWeeklySteps(filteredPrevSteps, prevStartDate, n);
      return StepCalculator.calculateAverageSteps(prevSteps);
    },
    bottomTitleFormat: (date) => DateFormat('M/d', Localizations.localeOf(context).languageCode).format(date),
  );
}

// Monthly Chart Implementation
Future<ChartData> _fetchMonthlyChartData(StepDatabase database, {int n = 7}) async {
  final endDate = DateTime.now();
  final startDate = DateTime(endDate.year, endDate.month - (n - 1), 1);

  final dataset = await database.getAllMonthlySteps(startDate, endDate);
  final average = await database.getDailyAverageSteps(startDate, endDate);
  final prefs = SharedPreferencesAsync();
  final displayRange = await prefs.getInt('monthlyChartRange') ?? 6;

  return ChartData(dataset, average, displayRange);
}

Widget buildLastNMonthsChart2(BuildContext context, StepDatabase database, {int n = 7}) {
  late Future<ChartData> chartDataFuture = _fetchMonthlyChartData(database, n: n);

  return FutureBuilder<ChartData>(
    future: chartDataFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      final chartData = snapshot.data!;
      return _buildBarChart2(
        context,
        chartData.dataset,
        ChartType.monthly,
        AppLocalizations.of(context)!.chartTitle(n, chartData.average),
        chartData.average,
        chartData.displayRange,
        30,
      );
    },
  );
}

Widget buildLastNMonthsChart(BuildContext context, StepDatabase database, {int n = 7}) {
  final DateTime today = DateTime.now();
  final DateTime startDate = DateTime(today.year, today.month - n + 1, 1);
  final DateTime prevStartDate = DateTime(today.year, today.month - n * 2 + 1, 1);

  return _buildStepChart(
    context: context,
    database: database,
    periods: n,
    titlePrefix: AppLocalizations.of(context)!.months,
    barWidth: 30,
    showDayOfWeek: false,
    processSteps: (steps) => StepCalculator.calculateMonthlySteps(steps, startDate, n),
    getCurrentValue: (steps) => steps.last.stepCount,
    getAverage: StepCalculator.calculateAverageSteps,
    // getPreviousAverage: (steps) {
    //   final prevSteps = StepCalculator.calculateMonthlySteps(steps, prevStartDate, n);
    //   return StepCalculator.calculateAverageSteps(prevSteps);
    // },
    getPreviousAverage: (steps) {
      final filteredPrevSteps =
          steps
              .where(
                (step) =>
                    DateTime.parse(step.date).isAfter(prevStartDate.subtract(const Duration(days: 1))) &&
                    DateTime.parse(step.date).isBefore(startDate),
              )
              .toList();
      final prevSteps = StepCalculator.calculateMonthlySteps(filteredPrevSteps, prevStartDate, n);
      return StepCalculator.calculateAverageSteps(prevSteps);
    },
    bottomTitleFormat: (date) => DateFormat('yyyy-MM', Localizations.localeOf(context).languageCode).format(date),
  );
}

Widget buildLastNYearsChart(BuildContext context, StepDatabase database, {int n = 5}) {
  final DateTime today = DateTime.now();
  final DateTime startDate = DateTime(today.year - (n - 1), 1, 1);
  final DateTime prevStartDate = DateTime(today.year - (n * 2 - 1), 1, 1);

  return _buildStepChart(
    context: context,
    database: database,
    periods: n,
    titlePrefix: AppLocalizations.of(context)!.years,
    barWidth: 20,
    showDayOfWeek: false,
    processSteps: (steps) {
      final List<DailyStep> filteredSteps = steps.where((step) => DateTime.parse(step.date).isAfter(startDate.subtract(Duration(days: 1)))).toList();
      final Map<DateTime, int> yearlySteps = <DateTime, int>{};
      for (final DailyStep step in filteredSteps) {
        final DateTime date = DateTime.parse(step.date);
        final DateTime yearStart = DateTime(date.year, 1, 1);
        yearlySteps[yearStart] = (yearlySteps[yearStart] ?? 0) + step.stepCount;
      }
      final List<DailyStep> sortedYears =
          yearlySteps.entries
              .map((e) => DailyStep(date: DateFormat('yyyy').format(e.key), stepCount: e.value, lastUpdated: DateTime.now(), isComplete: true))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      return sortedYears.length > n ? sortedYears.sublist(sortedYears.length - n) : sortedYears;
    },
    getCurrentValue: (steps) => steps.last.stepCount,
    getAverage: (steps) => steps.isEmpty ? 0 : steps.map((e) => e.stepCount).reduce((a, b) => a + b) / steps.length,
    getPreviousAverage: (steps) {
      final List<DailyStep> filteredSteps =
          steps
              .where(
                (step) =>
                    DateTime.parse(step.date).isAfter(prevStartDate.subtract(Duration(days: 1))) && DateTime.parse(step.date).isBefore(startDate),
              )
              .toList();
      final Map<DateTime, int> yearlySteps = <DateTime, int>{};
      for (final DailyStep step in filteredSteps) {
        final DateTime date = DateTime.parse(step.date);
        final DateTime yearStart = DateTime(date.year, 1, 1);
        yearlySteps[yearStart] = (yearlySteps[yearStart] ?? 0) + step.stepCount;
      }
      final List<DailyStep> prevYears =
          yearlySteps.entries
              .map((e) => DailyStep(date: DateFormat('yyyy').format(e.key), stepCount: e.value, lastUpdated: DateTime.now(), isComplete: true))
              .toList();
      return prevYears.isEmpty ? 0 : prevYears.map((e) => e.stepCount).reduce((a, b) => a + b) / prevYears.length;
    },
    bottomTitleFormat: (date) => DateFormat('yyyy').format(date),
  );
}

Widget buildHourlyHistogram(BuildContext context, List<HealthDataPoint> healthDataList) {
  final DateTime now = DateTime.now();
  final DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final Map<int, int> hourlyDistribution = <int, int>{};
  final SettingsModel settings = Provider.of<SettingsModel>(context);

  for (int i = 0; i < 24; i++) {
    hourlyDistribution[i] = 0;
  }

  int cumulativeSteps = 0;
  for (final HealthDataPoint data in healthDataList) {
    if (data.type == HealthDataType.STEPS && data.value is NumericHealthValue) {
      final int steps = (data.value as NumericHealthValue).numericValue.toInt();
      if (data.dateFrom.isAfter(todayStart) || data.dateFrom == todayStart) {
        final int totalDurationSeconds = data.dateTo.difference(data.dateFrom).inSeconds;
        if (data.dateFrom.hour == data.dateTo.hour) {
          final int hour = data.dateFrom.hour;
          hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + steps;
        } else {
          DateTime currentStart = data.dateFrom;
          int remainingSteps = steps;
          while (currentStart.isBefore(data.dateTo)) {
            DateTime hourEnd = DateTime(currentStart.year, currentStart.month, currentStart.day, currentStart.hour, 59, 59);
            if (hourEnd.isAfter(data.dateTo)) hourEnd = data.dateTo;
            final int segmentDurationSeconds = hourEnd.difference(currentStart).inSeconds;
            final int stepsForThisHour = (segmentDurationSeconds / totalDurationSeconds * steps).toInt();
            final int hour = currentStart.hour;
            if (currentStart.isAfter(todayStart.subtract(Duration(seconds: 1)))) {
              hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + stepsForThisHour;
            }
            remainingSteps -= stepsForThisHour;
            currentStart = hourEnd.add(Duration(seconds: 1));
          }
          if (remainingSteps > 0 && data.dateTo.isAfter(todayStart.subtract(Duration(seconds: 1)))) {
            hourlyDistribution[data.dateTo.hour] = (hourlyDistribution[data.dateTo.hour] ?? 0) + remainingSteps;
          }
        }
      }
    }
  }

  final Map<int, int> displayDistribution = Map.from(hourlyDistribution);
  if (settings.showCumulative) {
    for (int i = 0; i < 24; i++) {
      cumulativeSteps += hourlyDistribution[i] ?? 0;
      displayDistribution[i] = cumulativeSteps;
    }
  }

  final int totalSteps = displayDistribution[23] ?? cumulativeSteps; // Get total steps for title
  final int maxValue = displayDistribution.values.isNotEmpty ? displayDistribution.values.reduce((max, value) => max > value ? max : value) : 0;
  final double chartMaxY =
      maxValue > 0 ? (settings.showDailyStepGoal && settings.dailyStepGoal > maxValue ? settings.dailyStepGoal * 1.3 : maxValue * 1.3) : 10;

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
                  '${AppLocalizations.of(context)!.today}: $totalSteps ${AppLocalizations.of(context)!.steps}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.chartHelpTitle),
                          content: Text(AppLocalizations.of(context)!.hourlyStepsChartExplanation),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                        ),
                  );
                },
              ),
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
                        spots: List.generate(24, (hour) => FlSpot(hour.toDouble(), displayDistribution[hour]!.toDouble())),
                        isCurved: true,
                        color: _getTimeBasedColor(now.hour), // Using current hour for consistent color
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: _getTimeBasedColor(now.hour).withValues(alpha: .2)),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            // Skip the topmost value if it's close to chartMaxY
                            if (value >= chartMaxY * 0.95) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final int hour = value.toInt();
                            if (hour % 3 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '$hour:00',
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                              );
                            }
                            return const SizedBox();
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
                        bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), width: 1),
                        left: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), width: 1),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine:
                          (value) => FlLine(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), strokeWidth: 1, dashArray: [4, 4]),
                    ),
                    extraLinesData:
                        settings.showDailyStepGoal
                            ? ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: settings.dailyStepGoal.toDouble(),
                                  color: Colors.red.withValues(alpha: 0.7),
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                    labelResolver: (line) => 'Goal: ${settings.dailyStepGoal}',
                                  ),
                                ),
                              ],
                            )
                            : null,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.blueGrey[700]!,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final int hour = spot.x.toInt();
                            final int steps = spot.y.toInt();
                            return LineTooltipItem(
                              '$hour:00\n$steps steps',
                              const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            );
                          }).toList();
                        },
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
                      SizedBox(
                        height: 14,
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: settings.showCumulative,
                                onChanged: (value) {
                                  settings.setShowCumulative(value);
                                },
                                activeTrackColor: Colors.grey.withValues(alpha: 0.5),
                                activeColor: Colors.grey[600],
                                inactiveThumbColor: Colors.grey[400],
                                inactiveTrackColor: Colors.grey[200],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('Cumul.', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 14,
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: settings.showDailyStepGoal,
                                onChanged: (value) {
                                  settings.setShowDailyStepGoal(value);
                                },
                                activeTrackColor: Colors.grey.withValues(alpha: 0.5),
                                activeColor: Colors.grey[600],
                                inactiveThumbColor: Colors.grey[400],
                                inactiveTrackColor: Colors.grey[200],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('Goal', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
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

Color _getStepBasedColor(int steps, int maxSteps, int weekday) {
  // 計算步數相對於最大步數的比例（0.0 到 1.0）
  final double ratio = maxSteps > 0 ? steps / maxSteps : 0.0;
  final bool isWeekend = weekday == 6 || weekday == 7;
  final MaterialColor baseColor = isWeekend ? (weekday == 6 ? Colors.green : Colors.purple) : Colors.blue;

  if (ratio <= 0.1) return baseColor.shade100.withValues(alpha: 0.3); // 步數很少時，顏色很淡
  if (ratio <= 0.3) return Colors.cyan.shade600;
  if (ratio <= 0.5) return Colors.blue.shade300;
  if (ratio <= 0.7) return Colors.green.shade300;
  if (ratio <= 0.9) return Colors.teal.shade300; // 步數最多時，顏色最深
  return Colors.cyan.shade300;
}

Color _getTimeBasedColor(int hour) {
  final DateTime now = DateTime.now();
  if (hour > now.hour) {
    // 未來的時間：用灰色表示，設置透明度為 0.3
    return Colors.grey.withValues(alpha: 0.3);
  }
  if (hour < 6) return Colors.cyan.shade300;
  if (hour < 12) return Colors.blue.shade300;
  if (hour < 18) return Colors.green.shade400;
  return Colors.teal.shade300;
}

// Color _getDayBasedColor(int weekday) {
//   switch (weekday) {
//     case 1:
//       return Colors.blue.shade300;
//     case 2:
//       return Colors.blue.shade400;
//     case 3:
//       return Colors.blue.shade500;
//     case 4:
//       return Colors.blue.shade600;
//     case 5:
//       return Colors.blue.shade700;
//     case 6:
//       return Colors.green.shade400;
//     case 7:
//       return Colors.purple.shade400;
//     default:
//       return Colors.grey;
//   }
// }

// String _getLocalizedDayOfWeek(int weekday, AppLocalizations localizations) {
//   switch (weekday) {
//     case 1:
//       return localizations.monday;
//     case 2:
//       return localizations.tuesday;
//     case 3:
//       return localizations.wednesday;
//     case 4:
//       return localizations.thursday;
//     case 5:
//       return localizations.friday;
//     case 6:
//       return localizations.saturday;
//     case 7:
//       return localizations.sunday;
//     default:
//       return '';
//   }
// }
