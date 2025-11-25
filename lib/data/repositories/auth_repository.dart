import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/esp_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Registrar nuevo usuario

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String plate,
    required String emergencyContact,
    String role = 'user',
  }) async {
    try {
      // Crear usuario en Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      print("✅ Usuario autenticado, UID: $uid");

      // Enviar UID al ESP32
      await ESPService.enviarUidAlESP(uid);

      // Crear objeto de modelo
      final newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        plate: plate,
        emergencyContact: emergencyContact,
        role: role,
      );

      // //Guardar datos del usuario en Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toJson());

      // Guardar datos del usuario en Realtime Database
      await _db.child('users/$uid').set(newUser.toJson());
      print("✅ Usuario guardado correctamente en Realtime Database");

      // Guardar usuario activo en Realtime Database
      await guardarUsuarioActivo(uid);

      return newUser;
    } catch (e) {
      print("❌ Error al registrar usuario: $e");
      rethrow;
    }
  }

  /// Iniciar sesión
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      print("✅ Usuario inició sesión, UID: $uid");

      // Enviar UID al ESP32
      await ESPService.enviarUidAlESP(uid);

      // Cargar datos del usuario desde Realtime Database
      final snapshot = await _db.child('users/$uid').get();

      if (!snapshot.exists) {
        print("⚠️ No se encontró información del usuario en Realtime Database");
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final name = data['name'] ?? '';
      print("✅ Datos del usuario cargados correctamente");

      // Guardar usuario activo en Realtime Database
      await guardarUsuarioActivo(uid);

      return UserModel.fromJson(data);
    } catch (e) {
      print("❌ Error al iniciar sesión: $e");
      return null;
    }
  }

  /// Guardar el usuario activo en Realtime Database
  Future<void> guardarUsuarioActivo(String uid) async {
    try {
      await _db.child('session/activeUsers/$uid').set(true);
      print("✅ Usuario activo agregado: $uid");
    } catch (e) {
      print("❌ Error al guardar usuario activo: $e");
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
  try {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.child('session/activeUsers/$uid').remove();
    }
    await _auth.signOut();
    print("👋 Sesión cerrada correctamente");
  } catch (e) {
    print("❌ Error al cerrar sesión: $e");
  }
}

  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }
}
