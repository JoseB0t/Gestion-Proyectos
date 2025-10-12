import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;

  void _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate
    setState(() => loading = false);
    // In a real app call auth provider. For now navigate to home
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  //Image.asset('assets/logo.png', height: 110),
                  const SizedBox(height: 18),
                  Text('Bienvenido a NeuroDrive', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => email = v,
                    validator: (v) => v != null && v.contains('@') ? null : 'Correo inválido',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    onChanged: (v) => password = v,
                    validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Ingresar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
