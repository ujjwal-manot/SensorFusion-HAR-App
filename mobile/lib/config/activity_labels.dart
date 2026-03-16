import 'package:flutter/material.dart';

class ActivityLabels {
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
    'Stationary': Icons.accessibility_new,
    'Locomotion': Icons.directions_walk,
    'Vehicle': Icons.directions_car,
    'Gesture': Icons.pan_tool,
  };

  static const Map<String, Color> macroColors = {
    'Stationary': Color(0xFF4CAF50),
    'Locomotion': Color(0xFF2196F3),
    'Vehicle': Color(0xFFFF9800),
    'Gesture': Color(0xFF9C27B0),
  };
}
