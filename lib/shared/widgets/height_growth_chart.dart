import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/user_data_service.dart';
import '../../core/utils/height_calculator.dart';

/// Growth projection chart — Blueprint §6.5
/// Shows actual measurements (solid line with dots) + predicted target (dashed).
class HeightGrowthChart extends ConsumerWidget {
  final double currentHeight;
  final double predictedHeight;
  final int ageYears;
  final bool isMale;

  const HeightGrowthChart({
    super.key,
    required this.currentHeight,
    required this.predictedHeight,
    required this.ageYears,
    required this.isMale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(heightMeasurementsProvider);
    final planStartAsync = ref.watch(planStartDateProvider);

    return measurementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load chart')),
      data: (measurements) {
        final planStart = planStartAsync.asData?.value;
        return _buildChart(measurements, planStart);
      },
    );
  }

  Widget _buildChart(List<HeightEntry> measurements, DateTime? planStart) {
    // Projected growth curve over 12 weeks
    final curve = HeightCalculator.projectGrowthCurve(
      currentHeightCm: currentHeight,
      predictedHeightCm: predictedHeight,
      ageYears: ageYears,
      isMale: isMale,
    );

    final maxY = (predictedHeight + 3).ceilToDouble();
    final minY = (currentHeight - 2).floorToDouble();

    // Build spots from actual measurements positioned by date
    final measurementSpots = <FlSpot>[];
    if (planStart != null) {
      // Position by actual date relative to plan start
      for (final m in measurements) {
        final daysSinceStart = m.date.difference(planStart).inDays;
        final week = (daysSinceStart / 7).floor().clamp(0, curve.length - 1);
        measurementSpots.add(FlSpot(week.toDouble(), m.heightCm));
      }
    } else {
      // Fallback: position by index proportionally
      for (int i = 0; i < measurements.length; i++) {
        final x = measurements.length > 1
            ? (i / (measurements.length - 1)) * (curve.length - 1)
            : 0.0;
        measurementSpots.add(FlSpot(x, measurements[i].heightCm));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppTheme.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final week = value.toInt() + 1;
                return Text(
                  'W$week',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: AppTheme.textTertiary),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (curve.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // Projected growth curve (background line)
          LineChartBarData(
            spots: List.generate(curve.length,
                (i) => FlSpot(i.toDouble(), curve[i])),
            isCurved: true,
            color: AppTheme.accent.withOpacity(0.3),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withOpacity(0.05),
            ),
          ),

          // Predicted target (horizontal dashed line)
          LineChartBarData(
            spots: [
              FlSpot(0, predictedHeight),
              FlSpot((curve.length - 1).toDouble(), predictedHeight),
            ],
            isCurved: false,
            color: AppTheme.accentLight,
            barWidth: 2,
            dashArray: [8, 4],
            dotData: const FlDotData(show: false),
          ),

          // Actual measurements (solid line with dots)
          if (measurementSpots.length >= 2)
            LineChartBarData(
              spots: measurementSpots,
              isCurved: true,
              color: AppTheme.info,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isFirst = index == 0;
                  final isLast = index == measurementSpots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 5 : (isFirst ? 4 : 3),
                    color: isLast ? AppTheme.info : AppTheme.info.withOpacity(0.7),
                    strokeWidth: isLast ? 2.5 : 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: false,
              ),
            ),

          // Single measurement point
          if (measurementSpots.length == 1)
            LineChartBarData(
              spots: [
                FlSpot(0, currentHeight),
              ],
              isCurved: false,
              color: AppTheme.info,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 5,
                  color: AppTheme.info,
                  strokeWidth: 2.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} cm',
                GoogleFonts.interTextTheme().bodyMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
