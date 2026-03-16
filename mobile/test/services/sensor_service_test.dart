import 'package:flutter_test/flutter_test.dart';
import 'package:har_app/config/app_config.dart';
import 'package:har_app/models/sensor_sample.dart';

void main() {
  group('SensorSample', () {
    test('toList returns 9 values in correct order', () {
      final sample = SensorSample(
        ax: 1.0,
        ay: 2.0,
        az: 3.0,
        gx: 4.0,
        gy: 5.0,
        gz: 6.0,
        mx: 7.0,
        my: 8.0,
        mz: 9.0,
        timestampMs: 1000,
      );

      final list = sample.toList();
      expect(list.length, 9);
      expect(list[0], 1.0); // ax
      expect(list[1], 2.0); // ay
      expect(list[2], 3.0); // az
      expect(list[3], 4.0); // gx
      expect(list[4], 5.0); // gy
      expect(list[5], 6.0); // gz
      expect(list[6], 7.0); // mx
      expect(list[7], 8.0); // my
      expect(list[8], 9.0); // mz
    });

    test('SensorSample.zero() creates zeroed sample', () {
      final sample = SensorSample.zero();
      final list = sample.toList();
      expect(list.every((v) => v == 0.0), isTrue);
      expect(sample.timestampMs, greaterThan(0));
    });
  });

  group('AppConfig', () {
    test('has correct default values', () {
      expect(AppConfig.samplingRateHz, 50);
      expect(AppConfig.windowSize, 128);
      expect(AppConfig.strideSize, 16);
      expect(AppConfig.numChannels, 9);
      expect(AppConfig.bufferSize, 256);
      expect(AppConfig.confidenceThreshold, 0.6);
    });

    test('wsUrl derives from serverUrl', () {
      AppConfig.serverUrl = 'http://localhost:8000';
      expect(AppConfig.wsUrl, 'ws://localhost:8000');

      AppConfig.serverUrl = 'https://example.com';
      expect(AppConfig.wsUrl, 'wss://example.com');

      // Reset
      AppConfig.serverUrl = 'http://192.168.1.100:8000';
    });
  });

  group('Circular Buffer Logic', () {
    test('window extraction with zero padding when buffer is small', () {
      // Simulate circular buffer behavior
      const windowSize = 128;
      const numChannels = 9;
      final buffer = <List<double>>[];

      // Add only 10 samples
      for (int i = 0; i < 10; i++) {
        buffer.add(List.generate(numChannels, (ch) => (i * numChannels + ch).toDouble()));
      }

      // Extract window with zero padding
      final window = <List<double>>[];
      final padCount = windowSize - buffer.length;

      for (int i = 0; i < padCount; i++) {
        window.add(List.filled(numChannels, 0.0));
      }
      for (int i = 0; i < buffer.length; i++) {
        window.add(List.of(buffer[i]));
      }

      expect(window.length, windowSize);
      // First padCount entries should be zeros
      expect(window[0].every((v) => v == 0.0), isTrue);
      expect(window[padCount - 1].every((v) => v == 0.0), isTrue);
      // Last entries should be actual data
      expect(window[padCount][0], 0.0); // first sample ax
      expect(window[windowSize - 1][0], 81.0); // last sample ax = 9*9 = 81
    });

    test('window extraction from full circular buffer', () {
      const bufferSize = 256;
      const windowSize = 128;
      const numChannels = 9;
      final buffer = List.generate(
        bufferSize,
        (i) => List.generate(numChannels, (ch) => (i * numChannels + ch).toDouble()),
      );

      // Simulate bufferIndex pointing past end (wrapped around)
      const bufferIndex = 50; // means we wrote up to index 49

      final window = <List<double>>[];
      for (int i = 0; i < windowSize; i++) {
        final idx = (bufferIndex - windowSize + i + bufferSize) % bufferSize;
        window.add(List.of(buffer[idx]));
      }

      expect(window.length, windowSize);
      // First element should be buffer[(50 - 128 + 0 + 256) % 256] = buffer[178]
      expect(window[0][0], 178 * numChannels.toDouble());
      // Last element should be buffer[(50 - 128 + 127 + 256) % 256] = buffer[49]
      expect(window[windowSize - 1][0], 49 * numChannels.toDouble());
    });
  });
}
