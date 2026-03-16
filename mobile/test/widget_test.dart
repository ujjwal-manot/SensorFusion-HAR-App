import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:har_app/widgets/confidence_gauge.dart';
import 'package:har_app/widgets/activity_card.dart';
import 'package:har_app/models/activity_result.dart';
import 'package:har_app/config/activity_labels.dart';

void main() {
  group('ConfidenceGauge', () {
    testWidgets('displays percentage text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfidenceGauge(confidence: 0.85),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('displays 0% for zero confidence', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfidenceGauge(confidence: 0.0),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('displays 100% for full confidence', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfidenceGauge(confidence: 1.0),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('ActivityCard', () {
    testWidgets('shows placeholder when no activity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityCard(activity: null),
          ),
        ),
      );

      expect(find.text('No Activity Detected'), findsOneWidget);
      expect(find.text('Tap Start to begin recognition'), findsOneWidget);
    });

    testWidgets('shows activity details when provided', (tester) async {
      final result = ActivityResult(
        activity: 'Locomotion',
        macroCategory: 'locomotion',
        confidence: 0.92,
        latencyMs: 5.3,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActivityCard(activity: result),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Locomotion'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('5.3 ms'), findsOneWidget);
    });
  });

  group('ActivityLabels', () {
    test('macro labels has 4 entries', () {
      expect(ActivityLabels.macro.length, 4);
      expect(ActivityLabels.macro[0], 'Stationary');
      expect(ActivityLabels.macro[1], 'Locomotion');
      expect(ActivityLabels.macro[2], 'Vehicle');
      expect(ActivityLabels.macro[3], 'Gesture');
    });

    test('macroIcons has entries for all macro labels', () {
      for (final label in ActivityLabels.macro.values) {
        expect(ActivityLabels.macroIcons.containsKey(label), isTrue,
            reason: 'Missing icon for $label');
      }
    });

    test('macroColors has entries for all macro labels', () {
      for (final label in ActivityLabels.macro.values) {
        expect(ActivityLabels.macroColors.containsKey(label), isTrue,
            reason: 'Missing color for $label');
      }
    });

    test('fine labels exist for all macro categories', () {
      expect(ActivityLabels.fine.containsKey('stationary'), isTrue);
      expect(ActivityLabels.fine.containsKey('locomotion'), isTrue);
      expect(ActivityLabels.fine.containsKey('vehicle'), isTrue);
      expect(ActivityLabels.fine.containsKey('gesture'), isTrue);
    });
  });

  group('ActivityResult', () {
    test('toJson produces valid map', () {
      final now = DateTime.now();
      final result = ActivityResult(
        activity: 'Stationary',
        macroCategory: 'stationary',
        confidence: 0.95,
        latencyMs: 3.2,
        timestamp: now,
        sensorSnapshot: [1.0, 2.0, 3.0],
      );

      final json = result.toJson();
      expect(json['activity'], 'Stationary');
      expect(json['macro_category'], 'stationary');
      expect(json['confidence'], 0.95);
      expect(json['sensor_data'], [1.0, 2.0, 3.0]);
      expect(json['timestamp'], now.toIso8601String());
    });

    test('fromJson roundtrip works', () {
      final now = DateTime.now();
      final original = ActivityResult(
        activity: 'Vehicle',
        macroCategory: 'vehicle',
        confidence: 0.78,
        latencyMs: 4.5,
        timestamp: now,
        sensorSnapshot: [0.1, 0.2, 0.3],
      );

      final json = original.toJson();
      json['latency_ms'] = original.latencyMs;
      final restored = ActivityResult.fromJson(json);

      expect(restored.activity, original.activity);
      expect(restored.macroCategory, original.macroCategory);
      expect(restored.confidence, original.confidence);
      expect(restored.latencyMs, original.latencyMs);
    });
  });
}
