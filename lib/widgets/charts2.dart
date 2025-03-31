import 'package:dsteps/database/database.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:dsteps/utils/weekday_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChartDataType { daily, weekly, monthly }

// Helper class to hold chart data
class ChartData {
  final List<dynamic> dataset;
  final int average;
  final int displayRange;

  ChartData(this.dataset, this.average, this.displayRange);
}

Widget _buildBarChart(
  BuildContext context,
  List<dynamic> dataset,
  ChartDataType dataType,
  String title,
  int average,
  int displayRange,
  double barWidth,
) {
  final theme = Theme.of(context);
  final localizations = AppLocalizations.of(context)!;
  final isDarkTheme = theme.brightness == Brightness.dark;

  final sortedData = dataset..sort((a, b) => (a[0] as DateTime).compareTo(b[0] as DateTime));
  final displayData = sortedData.length > displayRange ? sortedData.sublist(sortedData.length - displayRange) : sortedData;

  bool showAverageLine = true;

  String formatDate(DateTime date) {
    switch (dataType) {
      case ChartDataType.daily:
        return DateFormat.EEEE(localizations.localeName).format(date);
      case ChartDataType.weekly:
        return DateFormat('M/d', localizations.localeName).format(date);
      case ChartDataType.monthly:
        return DateFormat.MMM(localizations.localeName).format(date);
    }
  }

  return GestureDetector(
    onHorizontalDragUpdate: (details) {
      showAverageLine = false;
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

// Daily Chart Implementation
Future<ChartData> _fetchDailyChartData(StepDatabase database, {int n = 7}) async {
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: n));

  final dataset = await database.getAllDailySteps();
  final average = await database.getDailyAverageSteps(startDate, endDate);
  final prefs = await SharedPreferences.getInstance();
  final displayRange = prefs.getInt('dailyChartRange') ?? 7;

  return ChartData(dataset, average, displayRange);
}

class DailyChartWidget extends StatefulWidget {
  final StepDatabase database;
  final int n;

  const DailyChartWidget({required this.database, this.n = 7});

  @override
  _DailyChartWidgetState createState() => _DailyChartWidgetState();
}

class _DailyChartWidgetState extends State<DailyChartWidget> {
  late Future<ChartData> _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _fetchDailyChartData(widget.database, n: widget.n);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChartData>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final chartData = snapshot.data!;
        return _buildBarChart(
          context,
          chartData.dataset,
          ChartDataType.daily,
          AppLocalizations.of(context)!.chartTitle(widget.n, chartData.average),
          chartData.average,
          chartData.displayRange,
          30,
        );
      },
    );
  }
}

// Weekly Chart Implementation
Future<ChartData> _fetchWeeklyChartData(StepDatabase database, {int n = 7}) async {
  final endDate = DateTime.now();
  final weekStart = await WeekdayUtils.getWeekStartDay();
  final daysToSubtract = (weekStart == Weekday.sunday ? 7 : 6) * (n - 1);
  final startDate = endDate.subtract(Duration(days: daysToSubtract));

  final dataset = await database.getAllWeeklySteps(startDate, endDate);
  final average = await database.getDailyAverageSteps(startDate, endDate);
  final prefs = await SharedPreferences.getInstance();
  final displayRange = prefs.getInt('weeklyChartRange') ?? 4;

  return ChartData(dataset, average, displayRange);
}

class WeeklyChartWidget extends StatefulWidget {
  final StepDatabase database;
  final int n;

  const WeeklyChartWidget({required this.database, this.n = 7});

  @override
  _WeeklyChartWidgetState createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget> {
  late Future<ChartData> _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _fetchWeeklyChartData(widget.database, n: widget.n);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChartData>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final chartData = snapshot.data!;
        return _buildBarChart(
          context,
          chartData.dataset,
          ChartDataType.weekly,
          AppLocalizations.of(context)!.chartTitle(widget.n, chartData.average),
          chartData.average,
          chartData.displayRange,
          30,
        );
      },
    );
  }
}

// Monthly Chart Implementation
Future<ChartData> _fetchMonthlyChartData(StepDatabase database, {int n = 7}) async {
  final endDate = DateTime.now();
  final startDate = DateTime(endDate.year, endDate.month - (n - 1), 1);

  final dataset = await database.getAllMonthlySteps(startDate, endDate);
  final average = await database.getDailyAverageSteps(startDate, endDate);
  final prefs = await SharedPreferences.getInstance();
  final displayRange = prefs.getInt('monthlyChartRange') ?? 6;

  return ChartData(dataset, average, displayRange);
}

class MonthlyChartWidget extends StatefulWidget {
  final StepDatabase database;
  final int n;

  const MonthlyChartWidget({required this.database, this.n = 7});

  @override
  _MonthlyChartWidgetState createState() => _MonthlyChartWidgetState();
}

class _MonthlyChartWidgetState extends State<MonthlyChartWidget> {
  late Future<ChartData> _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _fetchMonthlyChartData(widget.database, n: widget.n);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChartData>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final chartData = snapshot.data!;
        return _buildBarChart(
          context,
          chartData.dataset,
          ChartDataType.monthly,
          AppLocalizations.of(context)!.chartTitle(widget.n, chartData.average),
          chartData.average,
          chartData.displayRange,
          30,
        );
      },
    );
  }
}
