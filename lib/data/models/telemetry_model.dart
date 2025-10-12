class TelemetryModel {
  final double pressure; // FSR
  final double accelX;
  final double accelY;
  final double heartRate;
  final bool handsOnWheel;
  final DateTime timestamp;

  TelemetryModel({
    required this.pressure,
    required this.accelX,
    required this.accelY,
    required this.heartRate,
    required this.handsOnWheel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      pressure: (json['pressure'] as num).toDouble(),
      accelX: (json['accel_x'] as num).toDouble(),
      accelY: (json['accel_y'] as num).toDouble(),
      heartRate: (json['heart_rate'] as num).toDouble(),
      handsOnWheel: json['hands'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'pressure': pressure,
        'accel_x': accelX,
        'accel_y': accelY,
        'heart_rate': heartRate,
        'hands': handsOnWheel,
        'timestamp': timestamp.toIso8601String(),
      };
}
