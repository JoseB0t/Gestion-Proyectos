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
  
  // Inicializar FCM
  await FCMService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
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
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}