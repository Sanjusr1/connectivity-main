import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class SensorLineChart extends StatelessWidget {
  const SensorLineChart({
    required this.title,
    required this.history,
    required this.series,
    super.key,
  });

  final String title;
  final List<SensorData> history;
  final List<ChartSeries> series;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: history.length < 2
                ? Center(
                    child: Text(
                      'Start monitoring to draw live data.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (history.length - 1).toDouble(),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.textMuted.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: series
                          .map((item) => _lineBar(item))
                          .toList(),
                    ),
                  ),
          ),
          if (series.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: series
                  .map(
                    (item) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, color: item.color),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  LineChartBarData _lineBar(ChartSeries item) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < history.length; i++)
          FlSpot(i.toDouble(), item.valueBuilder(history[i])),
      ],
      color: item.color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.color,
    required this.valueBuilder,
  });

  final String label;
  final Color color;
  final double Function(SensorData data) valueBuilder;
}
