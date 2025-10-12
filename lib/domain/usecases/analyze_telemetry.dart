import 'dart:math';
import 'package:neurodrive/core/constants/app_constants.dart';
import 'package:neurodrive/domain/entities/telemetry.dart';

/// Analiza una Telemetry y devuelve:
/// 'normal', 'warning', 'danger'
class AnalyzeTelemetry {
  String call(Telemetry t) {
    // regla simple combinada (puedes reemplazar por TFLite en MCU o app)
    // Danger: manos fuera y baja presión y cambios bruscos o FC alta.
    final double accelMag = sqrt(t.accelX * t.accelX + t.accelY * t.accelY);

    // heurísticas:
    if (!t.handsOnWheel && t.pressure < AppConstants.minPressure && (t.heartRate > AppConstants.highHeartRate || accelMag > AppConstants.movementThreshold)) {
      return 'danger';
    }

    // Warning: manos flojas o FC levemente alta o movimiento inusual
    if ((t.pressure < AppConstants.minPressure) || (t.heartRate > AppConstants.highHeartRate * 0.9) || (accelMag > AppConstants.movementThreshold * 0.8)) {
      return 'warning';
    }

    return 'normal';
  }
}
