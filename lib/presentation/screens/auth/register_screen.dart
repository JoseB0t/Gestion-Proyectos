import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String phone = '';
  String plate = '';
  String emergency = '';
  bool loading = false;

  void _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate
    setState(() => loading = false);
    // ignore: use_build_context_synchronously
    Navigator.pop(context); // back to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              children: [
                //Image.asset('assets/logo.png', height: 90),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  onChanged: (v) => name = v,
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Obligatorio',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  onChanged: (v) => email = v,
                  validator: (v) => v != null && v.contains('@') ? null : 'Correo inválido',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  onChanged: (v) => password = v,
                  validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Placa del camión'),
                  onChanged: (v) => plate = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contacto de emergencia'),
                  onChanged: (v) => emergency = v,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
