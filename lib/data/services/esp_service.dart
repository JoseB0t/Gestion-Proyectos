import 'package:http/http.dart' as http;

class ESPService {
  /// Envía el UID actual al ESP32 mediante una petición HTTP
  static Future<void> enviarUidAlESP(String uid) async {
    try {
      // 🔹 Asegúrate de cambiar esta IP por la IP que muestra tu ESP32 en el monitor serial
      final uri = Uri.parse('http://172.16.3.182/setUser?uid=$uid');
      //final uri = Uri.parse('http://172.20.10.11/setUser?uid=$uid'); - wifi cel
      //final uri = Uri.parse('http://192.168.1.15/setUser?uid=$uid'); - wifi casa

      print("📡 Enviando UID al ESP32: $uid");
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        print('✅ UID enviado correctamente al ESP32');
      } else {
        print('⚠️ Error enviando UID: Código ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error conectando con el ESP32: $e');
      print('⚠️ Verifica que el ESP32 esté encendido y en la misma red WiFi');
    }
  }
}
