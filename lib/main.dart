import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/config/routes.dart';
import 'package:neurodrive/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NeuroDriveApp());
}

class NeuroDriveApp extends StatelessWidget {
  const NeuroDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroDrive',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}
