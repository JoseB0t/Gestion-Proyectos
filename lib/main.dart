import 'package:flutter/material.dart';
import 'package:neurodrive/presentation/screens/auth/login_screen.dart';
//import 'package:neurodrive/presentation/screens/history/history_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: LoginScreen()//HistoryScreen(),
      ),
    );
  }
}
