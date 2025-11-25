import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _baseUrl = 'http://172.16.2.35:8000/chat';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('reply')) {
          return data['reply'];
        } else if (data.containsKey('error')) {
          return "⚠️ Error del servidor: ${data['error']}";
        } else {
          return "❌ No se recibió respuesta válida del servidor.";
        }
      } else {
        return "❌ Error HTTP: ${response.statusCode}";
      }
    } catch (e) {
      return "🚫 Error de conexión con el servidor: $e";
    }
  }
}
