import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';
import 'package:neurodrive/data/services/hardware_bridge_service.dart';
import 'package:neurodrive/data/services/notification_service.dart';
import 'package:neurodrive/data/repositories/telemetry_repository.dart';
import 'package:neurodrive/data/models/telemetry_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String drivingStatus = 'normal';
  bool isTripActive = false;
  DateTime? startTime;
  Position? startPosition;
  Timer? sensorTimer;
  
  // Para monitoreo de telemetría
  StreamSubscription<TelemetryModel?>? _telemetrySubscription;
  final TelemetryMonitor _monitor = TelemetryMonitor();
  TelemetryModel? _currentTelemetry;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _startTelemetryMonitoring();
  }

  @override
  void dispose() {
    sensorTimer?.cancel();
    _telemetrySubscription?.cancel();
    super.dispose();
  }

  /// Iniciar monitoreo de telemetría en tiempo real
  void _startTelemetryMonitoring() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final repository = TelemetryRepository();
    _telemetrySubscription = repository.watchUserTelemetry(userId).listen((data) {
      if (data == null) return;
      
      setState(() {
        _currentTelemetry = data;
      });

      // Analizar y mostrar alertas
      final alert = _monitor.analyzeTelemetry(data);
      if (alert != null && mounted) {
        _handleAlert(alert);
      }
    });
  }

  /// Manejar alertas de telemetría
  void _handleAlert(TelemetryAlert alert) {
    switch (alert.severity) {
      case AlertSeverity.danger:
        // Notificación crítica + diálogo
        NotificationService.showCriticalAlert(
          title: '⚠️ ALERTA CRÍTICA',
          body: alert.message,
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        NotificationService.showCriticalDialog(
          context,
          title: 'Alerta de Seguridad',
          message: alert.message,
        );
        break;
      case AlertSeverity.warning:
        // Banner flotante
        NotificationService.showInAppBanner(
          context,
          message: alert.message,
          type: NotificationType.warning,
        );
        break;
      case AlertSeverity.info:
        NotificationService.showInAppBanner(
          context,
          message: alert.message,
          type: NotificationType.info,
        );
        break;
    }
  }

  void _simulateDrivingStatus() {
    final random = Random();
    final value = random.nextInt(100);

    setState(() {
      if (value < 60) {
        drivingStatus = 'normal';
      } else if (value < 85) {
        drivingStatus = 'warning';
      } else {
        drivingStatus = 'danger';
      }
    });
  }

  Future<void> _startTrip() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor activa la ubicación')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      isTripActive = true;
      startTime = DateTime.now();
      startPosition = position;
    });

    sensorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateDrivingStatus();
    });
  }

  Future<void> _endTrip() async {
    final endTime = DateTime.now();
    final endPosition = await Geolocator.getCurrentPosition();

    final duration = endTime.difference(startTime!);
    final distanceMeters = Geolocator.distanceBetween(
      startPosition!.latitude,
      startPosition!.longitude,
      endPosition.latitude,
      endPosition.longitude,
    );
    final distanceKm = (distanceMeters / 1000).toStringAsFixed(2);

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('trips')
        .add({
      'title': 'Viaje del ${startTime!.day}/${startTime!.month}',
      'startTime': startTime,
      'endTime': endTime,
      'duration': '${duration.inMinutes} min',
      'distance': '$distanceKm km',
      'status': drivingStatus,
    });

    sensorTimer?.cancel();

    setState(() {
      isTripActive = false;
      drivingStatus = 'normal';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viaje guardado correctamente')),
    );
  }

  /// Llamada de emergencia
  Future<void> _handleEmergencyCall() async {
    try {
      await CallService.callEmergency();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al llamar: $e')),
        );
      }
    }
  }

  /// Llamada a contacto de emergencia
  Future<void> _handleEmergencyContactCall() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final emergencyContact = authProvider.user?.emergencyContact ?? '';
      
      if (emergencyContact.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes contacto de emergencia registrado')),
        );
        return;
      }

      await CallService.callEmergencyContact(emergencyContact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    
    final Color bgColor;
    final IconData icon;
    final String message;

    switch (drivingStatus) {
      case 'danger':
        bgColor = Colors.red.shade600;
        icon = Icons.warning_rounded;
        message = 'Conducción peligrosa, ¡Detente!';
        break;
      case 'warning':
        bgColor = Colors.amber.shade600;
        icon = Icons.error_outline;
        message = 'Conducción temerosa, ¡Desacansa un poco!';
        break;
      default:
        bgColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        message = 'Conducción excelente, ¡Sigue así!';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroDrive'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          // Indicador de frecuencia cardíaca en tiempo real
          if (_currentTelemetry != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentTelemetry!.heartRate.toInt()} bpm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0C3C78)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.user?.name ?? 'Usuario',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    authProvider.user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 70),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: bgColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: isTripActive ? 55 : 70,
              width: isTripActive ? 200 : 250,
              child: ElevatedButton(
                onPressed: () {
                  isTripActive ? _endTrip() : _startTrip();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTripActive ? Colors.red : AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  isTripActive ? "Finalizar viaje" : "Iniciar viaje",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón SOS - Emergencias
          FloatingActionButton.extended(
            heroTag: 'emergency',
            onPressed: _handleEmergencyCall,
            label: const Text('SOS 911'),
            icon: const Icon(Icons.emergency),
            backgroundColor: Colors.red.shade600,
          ),
          const SizedBox(height: 12),
          // Botón contacto de emergencia
          FloatingActionButton.extended(
            heroTag: 'emergency_contact',
            onPressed: _handleEmergencyContactCall,
            label: const Text('Contacto'),
            icon: const Icon(Icons.phone),
            backgroundColor: Colors.deepOrange.shade600,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.grey.shade100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              color: AppTheme.primaryBlue,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.history),
              color: Colors.grey,
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            const SizedBox(width: 80), // Espacio para FABs
          ],
        ),
      ),
    );
  }
}