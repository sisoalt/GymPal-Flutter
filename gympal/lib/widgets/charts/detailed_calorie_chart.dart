import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/calorie_provider.dart';

class DetailedCalorieChart extends StatelessWidget {
  const DetailedCalorieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalorieProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        final end = DateTime(now.year, now.month, now.day);
        
        final statsMap = provider.getDailyMealStatsForRange(start, end);
        final List<DateTime> sortedDates = statsMap.keys.toList()..sort();
        final goal = provider.dailyGoal.toDouble();

        double maxCal = goal;
        for (var dayData in statsMap.values) {
          final total = dayData.values.fold(0, (sum, val) => sum + val);
          if (total > maxCal) maxCal = total.toDouble();
        }
        maxCal += 500;

        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Calorie Breakdown",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildLegend(context),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: maxCal,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueAccent,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dayData = statsMap[sortedDates[groupIndex]]!;
                          final total = dayData.values.fold(0, (sum, val) => sum + val);
                          return BarTooltipItem(
                            'Total: $total kcal\n'
                            'B: ${dayData['Breakfast']} L: ${dayData['Lunch']} D: ${dayData['Dinner']}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                            if (index < 0 || index >= sortedDates.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(sortedDates[index]),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: goal,
                          color: Colors.red.withAlpha((0.5 * 255).round()),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 5, bottom: 5),
                            style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                            labelResolver: (line) => 'Target: ${goal.toInt()}',
                          ),
                        ),
                      ],
                    ),
                    barGroups: List.generate(sortedDates.length, (i) {
                      final dayData = statsMap[sortedDates[i]]!;
                      final total = dayData.values.fold(0, (sum, val) => sum + val).toDouble();
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 2,
                        barRods: [
                          // Total Bar (Solid)
                          BarChartRodData(
                            toY: total,
                            color: Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()),
                            width: 10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          // Breakdown Bar (Stacked)
                          BarChartRodData(
                            toY: total,
                            width: 10,
                            borderRadius: BorderRadius.circular(2),
                            rodStackItems: [
                              BarChartRodStackItem(0, dayData['Breakfast']!.toDouble(), Colors.greenAccent),
                              BarChartRodStackItem(dayData['Breakfast']!.toDouble(), (dayData['Breakfast']! + dayData['Lunch']!).toDouble(), Colors.blueAccent),
                              BarChartRodStackItem((dayData['Breakfast']! + dayData['Lunch']!).toDouble(), (dayData['Breakfast']! + dayData['Lunch']! + dayData['Dinner']!).toDouble(), Colors.orangeAccent),
                              BarChartRodStackItem((dayData['Breakfast']! + dayData['Lunch']! + dayData['Dinner']!).toDouble(), (dayData['Breakfast']! + dayData['Lunch']! + dayData['Dinner']! + dayData['Snack']!).toDouble(), Colors.purpleAccent),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem(Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()), "Total"),
          const SizedBox(width: 4),
          _buildLegendItem(Colors.greenAccent, "B"),
          const SizedBox(width: 4),
          _buildLegendItem(Colors.blueAccent, "L"),
          const SizedBox(width: 4),
          _buildLegendItem(Colors.orangeAccent, "D"),
          const SizedBox(width: 4),
          _buildLegendItem(Colors.purpleAccent, "S"),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}
