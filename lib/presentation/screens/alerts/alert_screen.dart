import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/status_icon.dart';
import '../../state/telemetry_provider.dart';
import '../../widgets/custom_button.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});
  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  late String status;
  Timer? _countdown;
  int secondsLeft = 8;
  bool awaitingResponse = false;

  @override
  void initState() {
    super.initState();
    status = TelemetryProvider.instance.currentStatus;
  }

  void _startInteraction() {
    setState(() {
      awaitingResponse = true;
      secondsLeft = TelemetryProvider.instance.driverTimeout;
    });

    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsLeft -= 1;
        if (secondsLeft <= 0) {
          t.cancel();
          awaitingResponse = false;
          // create event and call SendAlert logic (which uses external services)
          TelemetryProvider.instance.generateEventFromCurrent(status);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta enviada (simulación)')));
        }
      });
    });

    // In a real app: play TTS and listen.
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    status = TelemetryProvider.instance.currentStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('Alerta')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Area central: only one of the three icons visible at a time
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: StatusIcon(
                    key: ValueKey(status),
                    status: status,
                    size: 160,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Text(_messageFor(status), style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  if (!awaitingResponse)
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(text: 'Preguntar al conductor', onPressed: _startInteraction),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // force send immediate event
                              TelemetryProvider.instance.generateEventFromCurrent(status);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta enviada (simulación)')));
                            },
                            child: const Text('Enviar alerta'),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Text('Esperando respuesta del conductor... ($secondsLeft s)'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: secondsLeft / TelemetryProvider.instance.driverTimeout),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _messageFor(String s) {
    switch (s) {
      case 'normal':
        return 'Conducción excelente, ¡Sigue así!';
      case 'warning':
        return 'Conducción temerosa, ¡Descansa un poco!';
      case 'danger':
        return 'Conducción peligrosa, ¡Detente ahora!';
      default:
        return 'Estado desconocido';
    }
  }
}
