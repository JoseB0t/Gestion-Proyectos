import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  /// Llamar a número de emergencia (911 o equivalente)
  static Future<void> callEmergency() async {
    await _makeCall('911'); // Cambia según tu país
  }

  /// Llamar al contacto de emergencia del usuario
  static Future<void> callEmergencyContact(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      throw Exception('No se ha registrado un contacto de emergencia');
    }
    await _makeCall(phoneNumber);
  }

  /// Método privado para realizar la llamada
  static Future<void> _makeCall(String phoneNumber) async {
    // Verificar permiso de teléfono (solo Android)
    if (await Permission.phone.isDenied) {
      final status = await Permission.phone.request();
      if (status.isDenied) {
        throw Exception('Permiso de teléfono denegado');
      }
    }

    // Limpiar número de espacios y guiones
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);
    
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      throw Exception('No se puede realizar la llamada');
    }
  }

  /// Enviar SMS al contacto de emergencia
  static Future<void> sendEmergencySMS(String phoneNumber, String message) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw Exception('No se puede enviar SMS');
    }
  }
}