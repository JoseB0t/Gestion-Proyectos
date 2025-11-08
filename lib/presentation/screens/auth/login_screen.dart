import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    await auth.login(email, password);

    if (auth.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${auth.error}')),
        );
      }
      return;
    }

    // Redirigir según el rol del usuario
    if (auth.user != null && mounted) {
      final userRole = auth.user!.role;
      
      if (userRole == 'admin') {
        // Redirigir a dashboard de administrador
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        // Redirigir a home de usuario normal
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo o icono
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.drive_eta,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenido a NeuroDrive',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Campo de email
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => email = v,
                    validator: (v) => v != null && v.contains('@') 
                        ? null 
                        : 'Correo inválido',
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de contraseña
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    onChanged: (v) => password = v,
                    validator: (v) => v != null && v.length >= 6 
                        ? null 
                        : 'Mínimo 6 caracteres',
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Ingresar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón de registro
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                  
                  // Recuperar contraseña
                  TextButton(
                    onPressed: () async {
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa tu correo primero'),
                          ),
                        );
                        return;
                      }
                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Correo de recuperación enviado'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}