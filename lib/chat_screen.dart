import 'package:flutter/material.dart';
import 'package:neurodrive/ia_service.dart';
import 'package:neurodrive/message_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final AiService _aiService = AiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _initTts();

    _messages.add(
      Message(
        text:
            "Hola 👋 soy tu asistente de conducción. Pulsa el micrófono y háblame cuando quieras.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 🔹 Solicita permisos de micrófono y configura reconocimiento de voz
  Future<void> _initPermissions() async {
    var status = await Permission.microphone.status;

    // Si nunca ha sido pedido, lo solicita
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) => print("onStatus: $status"),
        onError: (error) => print("onError: $error"),
      );
      print("🎤 Reconocimiento de voz inicializado correctamente");
    } else if (status.isPermanentlyDenied) {
      print(
        "⚠️ Permiso de micrófono permanentemente denegado. Abriendo configuración...",
      );
      await openAppSettings();
    } else {
      print("❌ Permiso de micrófono denegado");
    }
  }

  /// 🔹 Configura el motor de texto a voz (TTS)
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
  }

  /// 🔊 Habla el texto de respuesta de la IA
  Future<void> _speak(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print("⚠️ Error al reproducir voz: $e");
    }
  }

  /// 🎙️ Escucha la voz del usuario y procesa la respuesta
  Future<void> _listen() async {
    if (!_speechEnabled) {
      print("❌ Speech no inicializado correctamente");
      return;
    }

    if (!_isListening) {
      print("🎧 Escuchando...");
      setState(() => _isListening = true);
      await _speech.listen(
        localeId: 'es-ES', // o 'es-CO' si estás en Colombia 🇨🇴
        listenMode: stt.ListenMode.confirmation,
        onResult: (result) async {
          if (result.finalResult) {
            setState(() {
              _messages.add(
                Message(
                  text: result.recognizedWords,
                  isUser: true,
                  timestamp: DateTime.now(),
                ),
              );
              _isProcessing = true;
            });

            final aiResponse = await _aiService.sendMessage(
              result.recognizedWords,
            );
            setState(() {
              _messages.add(
                Message(
                  text: aiResponse,
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
              _isProcessing = false;
            });

            await _speak(aiResponse);
          }
        },
      );
    } else {
      print("🛑 Micrófono detenido.");
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Asistente de Conducción IA"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: FloatingActionButton(
              backgroundColor: _isListening
                  ? Colors.redAccent
                  : Colors.blueAccent,
              onPressed: _listen,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
