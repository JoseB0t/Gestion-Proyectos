import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/config/routes.dart';
import 'package:neurodrive/firebase_options.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
