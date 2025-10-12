import 'package:flutter/material.dart';
import 'package:neurodrive/presentation/screens/auth/login_screen.dart';
import 'package:neurodrive/presentation/screens/auth/register_screen.dart';
import 'package:neurodrive/presentation/screens/home/home_screen.dart';
import 'package:neurodrive/presentation/screens/alerts/alert_screen.dart';
import 'package:neurodrive/presentation/screens/history/history_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/home': (_) => const HomeScreen(),
  '/alert': (_) => const AlertScreen(),
  '/history': (_) =>  HistoryScreen(),
};
