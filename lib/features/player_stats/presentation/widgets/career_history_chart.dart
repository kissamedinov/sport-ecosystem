import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/player_stats/data/models/match_history_item.dart';

class CareerHistoryChart extends StatelessWidget {
  final List<MatchHistoryItem> history;

  const CareerHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: Text(
            "No career history yet",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    // Sort chronologically and limit to last 10 matches for the chart
    final sortedData = List<MatchHistoryItem>.from(history)
      ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
    
    final displayData = sortedData.length > 10 ? sortedData.sublist(sortedData.length - 10) : sortedData;

    List<FlSpot> spots = [];
    double maxGoals = 0;
    
    for (int i = 0; i < displayData.length; i++) {
        final goals = displayData[i].goals.toDouble();
        spots.add(FlSpot(i.toDouble(), goals));
        if (goals > maxGoals) maxGoals = goals;
    }

    // Ensure the chart has some headroom
    maxGoals = maxGoals < 3 ? 3 : maxGoals + 1;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "GOALS DYNAMICS", 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 12, 
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "LAST 10 MATCHES",
                  style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox();
                        return Text(
                          value.toInt().toString(), 
                          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (displayData.length - 1).toDouble() < 1 ? 1 : (displayData.length - 1).toDouble(),
                minY: 0,
                maxY: maxGoals,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: PremiumTheme.neonGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: PremiumTheme.surfaceBase(context),
                        strokeWidth: 2,
                        strokeColor: PremiumTheme.neonGreen,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          PremiumTheme.neonGreen.withValues(alpha: 0.3),
                          PremiumTheme.neonGreen.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          '${touchedSpot.y.toInt()} Goals',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
