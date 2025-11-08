import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/telemetry_model.dart';

class TelemetryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de telemetría en tiempo real para un usuario específico
  Stream<TelemetryModel?> watchUserTelemetry(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('telemetry')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TelemetryModel.fromJson(snapshot.docs.first.data());
    });
  }

  /// Guardar telemetría (esto lo hará el ESP32 o tu simulador)
  Future<void> saveTelemetry(String userId, TelemetryModel data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('telemetry')
        .add(data.toJson());
  }

  /// Obtener historial de telemetría
  Future<List<TelemetryModel>> getTelemetryHistory(
    String userId, {
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('telemetry')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => TelemetryModel.fromJson(doc.data()))
        .toList();
  }

  /// Análisis de telemetría (para dashboard admin)
  Future<Map<String, dynamic>> getTelemetryStats(String userId) async {
    final docs = await getTelemetryHistory(userId, limit: 50);
    
    if (docs.isEmpty) {
      return {
        'avgHeartRate': 0.0,
        'maxHeartRate': 0.0,
        'handsOnWheelPercentage': 0.0,
        'alertsCount': 0,
      };
    }

    final avgHR = docs.map((e) => e.heartRate).reduce((a, b) => a + b) / docs.length;
    final maxHR = docs.map((e) => e.heartRate).reduce((a, b) => a > b ? a : b);
    final handsOnCount = docs.where((e) => e.handsOnWheel).length;
    final handsOnPercentage = (handsOnCount / docs.length) * 100;
    
    // Contar alertas (frecuencia cardíaca > 100 o < 60, o manos fuera del volante)
    final alertsCount = docs.where((e) => 
      e.heartRate > 100 || e.heartRate < 60 || !e.handsOnWheel
    ).length;

    return {
      'avgHeartRate': avgHR,
      'maxHeartRate': maxHR,
      'handsOnWheelPercentage': handsOnPercentage,
      'alertsCount': alertsCount,
    };
  }
}

/// Provider para telemetría en tiempo real
class TelemetryMonitor {
  final TelemetryRepository _repository = TelemetryRepository();
  
  /// Rangos normales de frecuencia cardíaca
  static const double minNormalHeartRate = 60.0;
  static const double maxNormalHeartRate = 100.0;
  
  /// Umbral para movimiento brusco (aceleración en g)
  static const double harshMovementThreshold = 2.0;

  /// Analizar telemetría y retornar alertas
  TelemetryAlert? analyzeTelemetry(TelemetryModel? data) {
    if (data == null) return null;

    // Verificar frecuencia cardíaca
    if (data.heartRate < minNormalHeartRate) {
      return TelemetryAlert(
        type: AlertType.heartRateLow,
        severity: AlertSeverity.warning,
        message: 'Frecuencia cardíaca baja: ${data.heartRate.toInt()} bpm',
      );
    }
    
    if (data.heartRate > maxNormalHeartRate) {
      return TelemetryAlert(
        type: AlertType.heartRateHigh,
        severity: AlertSeverity.danger,
        message: 'Frecuencia cardíaca alta: ${data.heartRate.toInt()} bpm',
      );
    }

    // Verificar manos en el volante
    if (!data.handsOnWheel) {
      return TelemetryAlert(
        type: AlertType.handsOffWheel,
        severity: AlertSeverity.warning,
        message: 'Coloca las manos en el volante',
      );
    }

    // Verificar movimiento brusco
    final totalAccel = (data.accelX.abs() + data.accelY.abs());
    if (totalAccel > harshMovementThreshold) {
      return TelemetryAlert(
        type: AlertType.harshMovement,
        severity: AlertSeverity.danger,
        message: 'Movimiento brusco detectado',
      );
    }

    return null;
  }
}

class TelemetryAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;

  TelemetryAlert({
    required this.type,
    required this.severity,
    required this.message,
  });
}

enum AlertType {
  heartRateLow,
  heartRateHigh,
  handsOffWheel,
  harshMovement,
}

enum AlertSeverity {
  info,
  warning,
  danger,
}