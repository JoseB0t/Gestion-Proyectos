import 'dart:async';
import 'dart:math';
import 'package:neurodrive/domain/entities/telemetry.dart';
import 'package:neurodrive/domain/usecases/analyze_telemetry.dart';
import 'package:neurodrive/data/models/event_model.dart';
import 'package:neurodrive/core/utils/helpers.dart';
import 'package:neurodrive/presentation/state/event_provider.dart';

/// Singleton telemetry manager that simulates telemetry input (until real hardware is plugged)
class TelemetryProvider {
  TelemetryProvider._private();
  static final TelemetryProvider instance = TelemetryProvider._private();

  final AnalyzeTelemetry _analyzer = AnalyzeTelemetry();

  String currentStatus = 'normal';
  Timer? _simTimer;
  int driverTimeout = 8;

  final Random _rnd = Random();

  void startSimulation({Duration period = const Duration(seconds: 3)}) {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(period, (_) => _simulateTelemetry());
  }

  void stopSimulation() {
    _simTimer?.cancel();
    _simTimer = null;
  }

  void _simulateTelemetry() {
    // Randomly generate telemetry that sometimes produces warnings/danger
    final pressure = 0.1 + _rnd.nextDouble() * 1.0; // 0.1 - 1.1
    final accelX = (_rnd.nextDouble() - 0.5) * 2; // -1 .. 1
    final accelY = (_rnd.nextDouble() - 0.5) * 2;
    final hr = 60 + _rnd.nextInt(80); // 60..140
    final hands = _rnd.nextDouble() > 0.2; // 80% hands true

    final tm = Telemetry(
      pressure: pressure,
      accelX: accelX,
      accelY: accelY,
      heartRate: hr.toDouble(),
      handsOnWheel: hands,
      timestamp: DateTime.now(),
    );

    final s = _analyzer(tm);
    currentStatus = s;

    // if status is danger or warning, add to event queue (EventProvider)
    if (s != 'normal') {
      final ev = EventModel(
        id: uidNow(),
        type: s,
        timestamp: DateTime.now(),
        telemetry: {
          'pressure': pressure,
          'accel_x': accelX,
          'accel_y': accelY,
          'heart_rate': hr,
          'hands': hands,
        },
        status: 'pending',
      );
      EventProvider.instance.addEvent(ev);
    }
  }

  // Called from UI when we want to force-create an event from current snapshot
  void generateEventFromCurrent(String status) {
    final ev = EventModel(
      id: uidNow(),
      type: status,
      timestamp: DateTime.now(),
      telemetry: {'source': 'manual_trigger'},
      status: 'pending',
    );
    EventProvider.instance.addEvent(ev);
  }
}
