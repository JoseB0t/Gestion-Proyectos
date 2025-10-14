import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrar nuevo usuario
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String plate,
    required String emergencyContact,
  }) async {
    // Crear usuario en Firebase Authentication
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    // Crear objeto de modelo
    final newUser = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      plate: plate,
      emergencyContact: emergencyContact,
    );

    //Guardar datos del usuario en Firestore
    await _firestore.collection('users').doc(uid).set(newUser.toJson());

    return newUser;
  }

  /// Iniciar sesión
  Future<UserModel?> loginUser(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    // Cargar datos del usuario desde Firestore
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromJson(doc.data()!);
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}
