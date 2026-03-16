import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_sample.dart';

/// Premium sensor chart with gradient fills, curved lines, glow effects,
/// and a minimal clean aesthetic. No axes, no grid — just beautiful data.
class SensorChart extends ConsumerStatefulWidget {
  const SensorChart({super.key});

  @override
  ConsumerState<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends ConsumerState<SensorChart> {
  static const int _maxDataPoints = 100;
  final List<SensorSample> _samples = [];
  StreamSubscription? _subscription;

  // Vibrant line colors
  static const _xColor = Color(0xFF06B6D4); // cyan
  static const _yColor = Color(0xFFEC4899); // magenta
  static const _zColor = Color(0xFFF59E0B); // amber

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    final sensorService = ref.read(sensorServiceProvider);
    _subscription = sensorService.sampleStream.listen((sample) {
      if (!mounted) return;
      setState(() {
        _samples.add(sample);
        while (_samples.length > _maxDataPoints) {
          _samples.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_samples.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 32,
              color: AppTheme.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for sensor data...',
              style: TextStyle(
                color: AppTheme.textTertiary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Compute Y-axis bounds
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final s in _samples) {
      for (final v in [s.ax, s.ay, s.az]) {
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
    }
    final range = maxY - minY;
    final pad = max(range * 0.15, 0.5);
    minY -= pad;
    maxY += pad;

    final xSpots = <FlSpot>[];
    final ySpots = <FlSpot>[];
    final zSpots = <FlSpot>[];

    for (int i = 0; i < _samples.length; i++) {
      final s = _samples[i];
      xSpots.add(FlSpot(i.toDouble(), s.ax));
      ySpots.add(FlSpot(i.toDouble(), s.ay));
      zSpots.add(FlSpot(i.toDouble(), s.az));
    }

    return Column(
      children: [
        // Legend row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _legendDot(_xColor, 'X'),
            const SizedBox(width: 12),
            _legendDot(_yColor, 'Y'),
            const SizedBox(width: 12),
            _legendDot(_zColor, 'Z'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (_maxDataPoints - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                _buildLine(xSpots, _xColor),
                _buildLine(ySpots, _yColor),
                _buildLine(zSpots, _zColor),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      shadow: Shadow(
        color: color.withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}
