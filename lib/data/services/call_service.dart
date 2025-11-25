import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class CallService {
  /// Llamar al número de emergencia (123 en Colombia)
  static Future<void> callEmergency() async {
    const emergencyNumber = '123'; // Número de emergencia en Colombia
    await _makeCall(emergencyNumber);
  }

  /// Llamar al contacto de emergencia
  static Future<void> callEmergencyContact(String phoneNumber) async {
    // Limpiar el número (remover espacios, guiones, etc.)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si no tiene código de país, agregar +57 (Colombia)
    if (!cleanNumber.startsWith('+')) {
      if (cleanNumber.startsWith('57')) {
        cleanNumber = '+$cleanNumber';
      } else if (cleanNumber.length == 10) {
        // Número de 10 dígitos sin código de país
        cleanNumber = '+57$cleanNumber';
      }
    }
    
    await _makeCall(cleanNumber);
  }

  /// Hacer la llamada con permisos
  static Future<void> _makeCall(String phoneNumber) async {
    try {
      // Verificar y solicitar permiso de llamada
      PermissionStatus permission = await Permission.phone.status;
      
      if (!permission.isGranted) {
        // Solicitar permiso
        permission = await Permission.phone.request();
        
        if (!permission.isGranted) {
          // Si no se concede, abrir el marcador en lugar de llamar directamente
          await _openDialer(phoneNumber);
          return;
        }
      }

      // Hacer la llamada directamente
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'No se puede realizar la llamada';
      }
    } catch (e) {
      debugPrint('❌ Error al llamar: $e');
      // Fallback: abrir el marcador
      await _openDialer(phoneNumber);
    }
  }

  /// Abrir el marcador (no requiere permisos)
  static Future<void> _openDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'No se puede abrir el marcador';
    }
  }

  /// Solicitar permisos de forma anticipada (llamar en inicio de app)
  static Future<bool> requestPhonePermission(BuildContext context) async {
    PermissionStatus status = await Permission.phone.status;
    
    if (status.isGranted) {
      return true;
    }

    // Mostrar diálogo explicativo antes de solicitar
    bool? shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.blue),
            SizedBox(width: 8),
            Text('Permiso de Llamadas'),
          ],
        ),
        content: const Text(
          'NeuroDrive necesita acceso para realizar llamadas de emergencia automáticas cuando sea necesario.\n\n'
          'Este permiso solo se usará en situaciones de emergencia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) {
      return false;
    }

    // Solicitar permiso
    status = await Permission.phone.request();
    
    if (status.isPermanentlyDenied) {
      // Mostrar diálogo para ir a configuración
      if (context.mounted) {
        await _showSettingsDialog(context);
      }
      return false;
    }

    return status.isGranted;
  }

  /// Mostrar diálogo para ir a configuración
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Denegado'),
        content: const Text(
          'El permiso de llamadas ha sido denegado permanentemente. '
          'Por favor, habilítalo manualmente en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  /// Verificar si el número es válido para Colombia
  static bool isValidColombianNumber(String phoneNumber) {
    // Limpiar el número
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Números válidos en Colombia:
    // - 10 dígitos (móvil: 3XXXXXXXX)
    // - 7 dígitos (fijo en ciudades principales)
    // - Con código +57
    if (cleanNumber.length == 10 && cleanNumber.startsWith('3')) {
      return true;
    }
    
    if (cleanNumber.length == 12 && cleanNumber.startsWith('57')) {
      return true;
    }
    
    if (cleanNumber.length == 7) {
      return true;
    }
    
    return false;
  }
}