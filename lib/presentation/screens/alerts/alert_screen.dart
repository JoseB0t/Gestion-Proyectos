import 'package:flutter/material.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreen();
}

class _AlertScreen extends State<AlertScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('Alertas screen'),
    );
  }
}