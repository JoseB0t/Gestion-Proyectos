import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicializar el servicio y registrar sesión activa
  static Future<void> initialize() async {
    // Equivalente a: auth.onAuthStateChanged
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Usuario conectado - guardar su UID
        _database.ref('session/activeUser').set(user.uid);
        print('✅ Usuario activo registrado: ${user.uid}');
      } else {
        // Usuario desconectado
        _database.ref('session/activeUser').set(null);
        print('❌ No hay usuario activo');
      }
    });
  }

  /// Guardar datos de telemetría del ESP32
  /// Equivalente a: set(ref(db, "telemetry/userId/timestamp"), data)
  static Future<void> saveTelemetry({
    required String userId,
    required Map<String, dynamic> telemetryData,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _database
          .ref('users/$userId/telemetry/$timestamp')
          .set(telemetryData);
      print('✅ Telemetría guardada');
    } catch (e) {
      print('❌ Error guardando telemetría: $e');
    }
  }

  /// Escuchar telemetría en tiempo real
  /// Equivalente a: onValue(ref(db, "telemetry/userId"))
  static Stream<Map<String, dynamic>?> watchTelemetry(String userId) {
    return _database
        .ref('users/$userId/telemetry')
        .orderByKey()
        .limitToLast(1)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final lastEntry = data.values.last as Map<dynamic, dynamic>;
      
      return Map<String, dynamic>.from(lastEntry);
    });
  }

  /// Guardar estado del viaje
  /// Equivalente a: set(ref(db, "trips/userId/tripId"), tripData)
  static Future<void> saveTripStatus({
    required String userId,
    required String status,
    required Map<String, dynamic> tripData,
  }) async {
    try {
      await _database.ref('users/$userId/currentTrip').set({
        'status': status,
        'data': tripData,
        'timestamp': ServerValue.timestamp,
      });
      print('✅ Estado del viaje guardado');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Leer datos una sola vez
  /// Equivalente a: get(ref(db, "path"))
  static Future<Map<String, dynamic>?> getData(String path) async {
    try {
      final snapshot = await _database.ref(path).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('❌ Error leyendo datos: $e');
      return null;
    }
  }

  /// Escuchar cambios en tiempo real (genérico)
  /// Equivalente a: onValue(ref(db, "path"))
  static Stream<Map<String, dynamic>?> watchPath(String path) {
    return _database.ref(path).onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Actualizar solo un campo (merge)
  /// Equivalente a: update(ref(db, "path"), {field: value})
  static Future<void> updateField(String path, Map<String, dynamic> updates) async {
    try {
      await _database.ref(path).update(updates);
      print('✅ Campo actualizado');
    } catch (e) {
      print('❌ Error actualizando: $e');
    }
  }

  /// Eliminar datos
  /// Equivalente a: remove(ref(db, "path"))
  static Future<void> deleteData(String path) async {
    try {
      await _database.ref(path).remove();
      print('✅ Datos eliminados');
    } catch (e) {
      print('❌ Error eliminando: $e');
    }
  }
}