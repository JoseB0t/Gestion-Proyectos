class Telemetry {
  final double pressure;
  final double accelX;
  final double accelY;
  final double heartRate;
  final bool handsOnWheel;
  final DateTime timestamp;

  Telemetry({
    required this.pressure,
    required this.accelX,
    required this.accelY,
    required this.heartRate,
    required this.handsOnWheel,
    required this.timestamp,
  });
}
