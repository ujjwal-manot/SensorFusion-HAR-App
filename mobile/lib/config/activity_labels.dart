import 'package:flutter/material.dart';
import 'theme.dart';

class ActivityLabels {
  ActivityLabels._();

  static const Map<int, String> macro = {
    0: 'Stationary',
    1: 'Locomotion',
    2: 'Vehicle',
    3: 'Gesture',
  };

  static const Map<String, Map<int, String>> fine = {
    'stationary': {
      0: 'Standing',
      1: 'Sitting',
      2: 'Lying Down',
      3: 'Leaning',
    },
    'locomotion': {
      0: 'Walking',
      1: 'Running',
      2: 'Stairs Up',
      3: 'Stairs Down',
      4: 'Jogging',
      5: 'Cycling',
    },
    'vehicle': {
      0: 'Car',
      1: 'Bus',
      2: 'Train',
      3: 'Stationary Vehicle',
    },
    'gesture': {
      0: 'Phone Pickup',
      1: 'Phone Putdown',
      2: 'Shaking',
      3: 'Flipping',
      4: 'Typing',
      5: 'Calling',
    },
  };

  static const Map<String, IconData> macroIcons = {
    'Stationary': Icons.self_improvement,
    'Locomotion': Icons.directions_run,
    'Vehicle': Icons.commute,
    'Gesture': Icons.touch_app,
  };

  static const Map<String, Color> macroColors = {
    'Stationary': Color(0xFF10B981),
    'Locomotion': Color(0xFF3B82F6),
    'Vehicle': Color(0xFFF59E0B),
    'Gesture': Color(0xFF8B5CF6),
  };

  static List<Color> macroGradient(String activity) {
    return AppTheme.gradientForCategory(activity);
  }
}
