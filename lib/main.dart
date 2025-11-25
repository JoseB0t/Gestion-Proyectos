import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/config/routes.dart';
import 'package:neurodrive/firebase_options.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';
import 'package:neurodrive/data/services/fcm_service.dart';
//import 'package:neurodrive/data/services/realtime_database_service.dart';
import 'package:neurodrive/data/services/notification_service.dart';
import 'package:neurodrive/chat_screen.dart';

// Handler para mensajes en segundo plano (debe estar fuera de main)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Mensaje en segundo plano: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar handler de mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar Realtime Database
  //await RealtimeDatabaseService.initialize();

  // Inicializar notificaciones
  await NotificationService.initialize();

  // Inicializar FCM
  await FCMService.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppAuthProvider())],
      child: const NeuroDriveApp(),
    ),
  );
}

class NeuroDriveApp extends StatelessWidget {
  const NeuroDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroDrive',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      // No hay sesión → login
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
    } else {
      // Sí hay sesión → Obtener rol desde Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser!.uid)
          .get()
          .then((snap) {
        final role = snap.data()?['role'] ?? 'user';

        RoleBasedNavigation.navigateAfterLogin(context, role);
      });
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

