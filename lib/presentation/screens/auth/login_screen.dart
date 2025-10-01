import 'package:flutter/material.dart';

import 'package:neurodrive/presentation/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Incio de Sesión')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 45.0,
                vertical: 8.0,
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 45.0,
                vertical: 8.0,
              ),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen()),
                );
              },
              child: Text('Iniciar Sesión'),
            ),
            TextButton(
              onPressed: () {},
              child: Text('¿Olvidaste tu contraseña?'),
            ),
            TextButton(
              onPressed: () {},
              child: Text('¿No tienes una cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}
