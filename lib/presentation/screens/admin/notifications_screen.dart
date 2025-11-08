import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/data/services/fcm_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String notificationType = 'all'; // all, specific, alert
  String? selectedUserId;
  bool isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Notificaciones'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Nueva Notificación',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Envía alertas importantes a tus conductores',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de notificación
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destinatarios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<String>(
                        title: const Text('Todos los conductores'),
                        subtitle: const Text('Enviar a todos los usuarios registrados'),
                        value: 'all',
                        groupValue: notificationType,
                        onChanged: (value) {
                          setState(() {
                            notificationType = value!;
                            selectedUserId = null;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Conductor específico'),
                        subtitle: const Text('Selecciona un conductor'),
                        value: 'specific',
                        groupValue: notificationType,
                        onChanged: (value) {
                          setState(() {
                            notificationType = value!;
                          });
                        },
                      ),
                      
                      // Selector de conductor
                      if (notificationType == 'specific')
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: _UserSelector(
                            selectedUserId: selectedUserId,
                            onUserSelected: (userId) {
                              setState(() => selectedUserId = userId);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título de la notificación
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej: Alerta de Mantenimiento',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mensaje
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  hintText: 'Escribe el mensaje de la notificación',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El mensaje es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Plantillas rápidas
              const Text(
                'Plantillas Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TemplateChip(
                    label: '⚠️ Mantenimiento',
                    onTap: () => _applyTemplate(
                      'Mantenimiento Programado',
                      'Recuerda realizar el mantenimiento de tu vehículo.',
                    ),
                  ),
                  _TemplateChip(
                    label: '🎉 Felicitaciones',
                    onTap: () => _applyTemplate(
                      '¡Excelente Conducción!',
                      'Has completado 10 viajes seguros. ¡Sigue así!',
                    ),
                  ),
                  _TemplateChip(
                    label: '📢 Actualización',
                    onTap: () => _applyTemplate(
                      'Nueva Actualización',
                      'Actualiza la app para acceder a nuevas funciones.',
                    ),
                  ),
                  _TemplateChip(
                    label: '⛽ Combustible',
                    onTap: () => _applyTemplate(
                      'Recordatorio',
                      'Revisa el nivel de combustible antes de tu próximo viaje.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de envío
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSending ? null : _sendNotification,
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isSending ? 'Enviando...' : 'Enviar Notificación',
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Aplicar plantilla
  void _applyTemplate(String title, String message) {
    setState(() {
      _titleController.text = title;
      _messageController.text = message;
    });
  }

  // Enviar notificación
  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (notificationType == 'specific' && selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un conductor'),
        ),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      final title = _titleController.text;
      final body = _messageController.text;

      if (notificationType == 'all') {
        // Enviar a todos
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();

        for (var userDoc in usersSnapshot.docs) {
          await FCMService.sendNotificationToUser(
            userId: userDoc.id,
            title: title,
            body: body,
            data: {'type': 'admin_message'},
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notificación enviada a ${usersSnapshot.docs.length} conductores'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Enviar a uno específico
        await FCMService.sendNotificationToUser(
          userId: selectedUserId!,
          title: title,
          body: body,
          data: {'type': 'admin_message'},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificación enviada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Limpiar formulario
      _titleController.clear();
      _messageController.clear();
      setState(() {
        notificationType = 'all';
        selectedUserId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isSending = false);
    }
  }
}

// Widget selector de usuario
class _UserSelector extends StatelessWidget {
  final String? selectedUserId;
  final Function(String) onUserSelected;

  const _UserSelector({
    required this.selectedUserId,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final users = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedUserId,
          decoration: const InputDecoration(
            labelText: 'Seleccionar conductor',
            border: OutlineInputBorder(),
          ),
          items: users.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['name'] ?? 'Sin nombre'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onUserSelected(value);
            }
          },
        );
      },
    );
  }
}

// Widget chip de plantilla
class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: AppTheme.primaryBlue),
    );
  }
}