import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_sample.dart';

class SensorChart extends ConsumerStatefulWidget {
  const SensorChart({super.key});

  @override
  ConsumerState<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends ConsumerState<SensorChart> {
  static const int _maxDataPoints = 100;
  final List<SensorSample> _samples = [];
  StreamSubscription? _subscription;

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
        child: Text(
          'Waiting for sensor data...',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Compute Y axis bounds
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final s in _samples) {
      final vals = [s.ax, s.ay, s.az];
      for (final v in vals) {
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
    }
    // Add padding
    final range = maxY - minY;
    final padding = max(range * 0.1, 0.5);
    minY -= padding;
    maxY += padding;

    final xSpots = <FlSpot>[];
    final ySpots = <FlSpot>[];
    final zSpots = <FlSpot>[];

    for (int i = 0; i < _samples.length; i++) {
      final s = _samples[i];
      xSpots.add(FlSpot(i.toDouble(), s.ax));
      ySpots.add(FlSpot(i.toDouble(), s.ay));
      zSpots.add(FlSpot(i.toDouble(), s.az));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_maxDataPoints - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: max((maxY - minY) / 4, 0.1),
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
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          _buildLine(xSpots, Colors.red, 'X'),
          _buildLine(ySpots, Colors.green, 'Y'),
          _buildLine(zSpots, Colors.blue, 'Z'),
        ],
      ),
      duration: const Duration(milliseconds: 0),
    );
  }

  LineChartBarData _buildLine(
      List<FlSpot> spots, Color color, String label) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 1.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
