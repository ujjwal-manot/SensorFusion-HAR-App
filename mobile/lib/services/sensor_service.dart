import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../config/app_config.dart';
import '../models/sensor_sample.dart';

class SensorService {
  final List<List<double>> _buffer = [];
  int _bufferIndex = 0;
  int _sampleCount = 0;
  bool _isActive = false;

  double _latestAx = 0, _latestAy = 0, _latestAz = 0;
  double _latestGx = 0, _latestGy = 0, _latestGz = 0;
  double _latestMx = 0, _latestMy = 0, _latestMz = 0;

  StreamSubscription? _accSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  Timer? _samplingTimer;

  final _windowController =
      StreamController<List<List<double>>>.broadcast();
  final _sampleController = StreamController<SensorSample>.broadcast();

  Stream<List<List<double>>> get windowStream => _windowController.stream;
  Stream<SensorSample> get sampleStream => _sampleController.stream;
  bool get isActive => _isActive;

  void start() {
    if (_isActive) return;
    _isActive = true;

    _buffer.clear();
    _bufferIndex = 0;
    _sampleCount = 0;

    // Initialize buffer with zeros
    for (int i = 0; i < AppConfig.bufferSize; i++) {
      _buffer.add(List.filled(AppConfig.numChannels, 0.0));
    }

    // Subscribe to accelerometer
    _accSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _latestAx = event.x;
      _latestAy = event.y;
      _latestAz = event.z;
    });

    // Subscribe to gyroscope
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _latestGx = event.x;
      _latestGy = event.y;
      _latestGz = event.z;
    });

    // Subscribe to magnetometer
    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _latestMx = event.x;
      _latestMy = event.y;
      _latestMz = event.z;
    });

    // 50Hz sampling timer (20ms interval)
    final samplingInterval = Duration(
      milliseconds: (1000 / AppConfig.samplingRateHz).round(),
    );
    _samplingTimer = Timer.periodic(samplingInterval, (_) {
      _onSamplingTick();
    });
  }

  void _onSamplingTick() {
    final sample = [
      _latestAx, _latestAy, _latestAz,
      _latestGx, _latestGy, _latestGz,
      _latestMx, _latestMy, _latestMz,
    ];

    // Write into circular buffer
    _buffer[_bufferIndex] = List.of(sample);
    _bufferIndex = (_bufferIndex + 1) % AppConfig.bufferSize;
    _sampleCount++;

    // Emit individual sample for charting
    final sensorSample = SensorSample(
      ax: _latestAx,
      ay: _latestAy,
      az: _latestAz,
      gx: _latestGx,
      gy: _latestGy,
      gz: _latestGz,
      mx: _latestMx,
      my: _latestMy,
      mz: _latestMz,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (!_sampleController.isClosed) {
      _sampleController.add(sensorSample);
    }

    // Every strideSize new samples, emit a window
    if (_sampleCount >= AppConfig.windowSize &&
        _sampleCount % AppConfig.strideSize == 0) {
      final window = _extractWindow();
      if (!_windowController.isClosed) {
        _windowController.add(window);
      }
    }
  }

  List<List<double>> _extractWindow() {
    final window = <List<double>>[];
    final totalSamples = _sampleCount < AppConfig.bufferSize
        ? _sampleCount
        : AppConfig.bufferSize;

    if (totalSamples < AppConfig.windowSize) {
      // Pad with zeros at the start
      final padCount = AppConfig.windowSize - totalSamples;
      for (int i = 0; i < padCount; i++) {
        window.add(List.filled(AppConfig.numChannels, 0.0));
      }
      // Add all available samples
      for (int i = 0; i < totalSamples; i++) {
        final idx = (_bufferIndex - totalSamples + i + AppConfig.bufferSize) %
            AppConfig.bufferSize;
        window.add(List.of(_buffer[idx]));
      }
    } else {
      // Extract last windowSize samples from circular buffer
      for (int i = 0; i < AppConfig.windowSize; i++) {
        final idx =
            (_bufferIndex - AppConfig.windowSize + i + AppConfig.bufferSize) %
                AppConfig.bufferSize;
        window.add(List.of(_buffer[idx]));
      }
    }

    return window;
  }

  void stop() {
    _isActive = false;
    _accSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _samplingTimer?.cancel();
    _accSub = null;
    _gyroSub = null;
    _magSub = null;
    _samplingTimer = null;
  }

  void dispose() {
    stop();
    _windowController.close();
    _sampleController.close();
  }
}
