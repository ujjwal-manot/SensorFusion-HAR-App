class SensorSample {
  final double ax, ay, az;
  final double gx, gy, gz;
  final double mx, my, mz;
  final int timestampMs;

  const SensorSample({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.mx,
    required this.my,
    required this.mz,
    required this.timestampMs,
  });

  List<double> toList() => [ax, ay, az, gx, gy, gz, mx, my, mz];

  factory SensorSample.zero() => SensorSample(
        ax: 0,
        ay: 0,
        az: 0,
        gx: 0,
        gy: 0,
        gz: 0,
        mx: 0,
        my: 0,
        mz: 0,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
}
