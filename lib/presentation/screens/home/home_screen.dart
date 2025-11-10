import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';
import 'package:neurodrive/data/services/hardware_bridge_service.dart';
import 'package:neurodrive/data/services/notification_service.dart';
import 'package:neurodrive/data/services/realtime_database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado del viaje
  bool isTripActive = false;
  DateTime? startTime;
  Position? startPosition;
  
  // Suscripción a telemetría en tiempo real
  StreamSubscription<Map<String, dynamic>?>? _telemetrySubscription;
  
  // Datos de telemetría actuales (desde ESP32)
  double currentHeartRate = 0.0;
  bool handsOnWheel = true;
  double accelX = 0.0;
  double accelY = 0.0;
  double pressure = 0.0;
  DateTime? lastTelemetryUpdate;
  
  // Estado de conducción calculado
  DrivingStatus drivingStatus = DrivingStatus.normal;
  
  // Control de alertas (evitar spam)
  DateTime? _lastHeartRateAlert;
  DateTime? _lastHandsAlert;
  DateTime? _lastMovementAlert;
  final Duration _alertCooldown = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _startTelemetryMonitoring();
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    super.dispose();
  }

  /// Monitorear telemetría en tiempo real desde Firebase Realtime Database
  void _startTelemetryMonitoring() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Escuchar cambios en tiempo real
    _telemetrySubscription = RealtimeDatabaseService
        .watchTelemetry(userId)
        .listen(
          _handleTelemetryUpdate,
          onError: (error) {
            debugPrint('❌ Error en telemetría: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error de conexión: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
  }

  /// Manejar actualización de telemetría
  void _handleTelemetryUpdate(Map<String, dynamic>? data) {
    if (data == null || !mounted) return;
    
    setState(() {
      currentHeartRate = (data['heartRate'] as num?)?.toDouble() ?? 0.0;
      handsOnWheel = data['handsOnWheel'] as bool? ?? true;
      accelX = (data['accelX'] as num?)?.toDouble() ?? 0.0;
      accelY = (data['accelY'] as num?)?.toDouble() ?? 0.0;
      pressure = (data['pressure'] as num?)?.toDouble() ?? 0.0;
      
      // Actualizar timestamp
      if (data['timestamp'] != null) {
        try {
          lastTelemetryUpdate = DateTime.parse(data['timestamp']);
        } catch (e) {
          lastTelemetryUpdate = DateTime.now();
        }
      } else {
        lastTelemetryUpdate = DateTime.now();
      }
    });

    // Analizar estado de conducción
    _analyzeDrivingStatus();
    
    // Verificar alertas (solo si hay viaje activo)
    if (isTripActive) {
      _checkTelemetryAlerts();
    }
  }

  /// Analizar y actualizar estado de conducción
  void _analyzeDrivingStatus() {
    DrivingStatus newStatus = DrivingStatus.normal;
    
    // Verificar condiciones peligrosas
    final bool criticalHeartRate = currentHeartRate > 120 || currentHeartRate < 50;
    final bool highHeartRate = currentHeartRate > 100 || currentHeartRate < 60;
    final bool harshMovement = (accelX.abs() + accelY.abs()) > 3.0;
    final bool noHands = !handsOnWheel;
    
    if (criticalHeartRate || (harshMovement && noHands)) {
      newStatus = DrivingStatus.danger;
    } else if (highHeartRate || harshMovement || noHands) {
      newStatus = DrivingStatus.warning;
    }
    
    if (mounted && drivingStatus != newStatus) {
      setState(() {
        drivingStatus = newStatus;
      });
    }
  }

  /// Verificar alertas de telemetría (con cooldown para evitar spam)
  void _checkTelemetryAlerts() {
    final now = DateTime.now();
    
    // Alerta: Frecuencia cardíaca anormal
    if (currentHeartRate > 0) {
      if (currentHeartRate < 50 || currentHeartRate > 120) {
        if (_lastHeartRateAlert == null || 
            now.difference(_lastHeartRateAlert!) > _alertCooldown) {
          _showHeartRateAlert(critical: true);
          _lastHeartRateAlert = now;
        }
      } else if (currentHeartRate < 60 || currentHeartRate > 100) {
        if (_lastHeartRateAlert == null || 
            now.difference(_lastHeartRateAlert!) > _alertCooldown) {
          _showHeartRateAlert(critical: false);
          _lastHeartRateAlert = now;
        }
      }
    }

    // Alerta: Manos fuera del volante
    if (!handsOnWheel) {
      if (_lastHandsAlert == null || 
          now.difference(_lastHandsAlert!) > const Duration(seconds: 10)) {
        _showHandsAlert();
        _lastHandsAlert = now;
      }
    }

    // Alerta: Movimiento brusco
    final totalAccel = accelX.abs() + accelY.abs();
    if (totalAccel > 3.0) {
      if (_lastMovementAlert == null || 
          now.difference(_lastMovementAlert!) > const Duration(seconds: 20)) {
        _showMovementAlert();
        _lastMovementAlert = now;
      }
    }
  }

  /// Mostrar alerta de frecuencia cardíaca
  void _showHeartRateAlert({required bool critical}) {
    final int hr = currentHeartRate.toInt();
    
    NotificationService.showCriticalAlert(
      title: critical ? '🚨 ALERTA CRÍTICA' : '⚠️ Atención',
      body: critical
          ? 'Frecuencia cardíaca: $hr bpm. Detente inmediatamente.'
          : 'Frecuencia cardíaca: $hr bpm. Considera descansar.',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
    if (critical && mounted) {
      NotificationService.showCriticalDialog(
        context,
        title: '🚨 ALERTA CRÍTICA',
        message: 'Tu frecuencia cardíaca está en $hr bpm. Por tu seguridad, detente ahora.',
        onDismiss: () {
          // Opcional: Notificar a contacto de emergencia
        },
      );
    }
  }

  /// Mostrar alerta de manos fuera del volante
  void _showHandsAlert() {
    NotificationService.showCriticalAlert(
      title: '✋ Manos en el Volante',
      body: 'Por favor, coloca ambas manos en el volante',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Mostrar alerta de movimiento brusco
  void _showMovementAlert() {
    NotificationService.showCriticalAlert(
      title: '🚗 Movimiento Brusco Detectado',
      body: 'Conduce con más suavidad para tu seguridad',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Iniciar viaje
  Future<void> _startTrip() async {
    try {
      // Verificar permisos de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor activa la ubicación')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // Obtener posición inicial
      final position = await Geolocator.getCurrentPosition();

      setState(() {
        isTripActive = true;
        startTime = DateTime.now();
        startPosition = position;
        drivingStatus = DrivingStatus.normal;
      });

      // Registrar inicio del viaje en Realtime Database
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await RealtimeDatabaseService.saveTripStatus(
          userId: userId,
          status: 'active',
          tripData: {
            'startTime': startTime!.toIso8601String(),
            'startLat': position.latitude,
            'startLng': position.longitude,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje iniciado. Conduce con seguridad.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Finalizar viaje
  Future<void> _endTrip() async {
    if (startTime == null || startPosition == null) return;

    try {
      final endTime = DateTime.now();
      final endPosition = await Geolocator.getCurrentPosition();

      // Calcular duración y distancia
      final duration = endTime.difference(startTime!);
      final distanceMeters = Geolocator.distanceBetween(
        startPosition!.latitude,
        startPosition!.longitude,
        endPosition.latitude,
        endPosition.longitude,
      );
      final distanceKm = (distanceMeters / 1000).toStringAsFixed(2);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Determinar estado final del viaje
      final String tripStatus = _getTripStatusString();

      // Guardar en Firestore (historial permanente)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .add({
        'title': 'Viaje del ${startTime!.day}/${startTime!.month}/${startTime!.year}',
        'startTime': startTime,
        'endTime': endTime,
        'duration': '${duration.inMinutes} min',
        'distance': '$distanceKm km',
        'status': tripStatus,
        'avgHeartRate': currentHeartRate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar estado en Realtime Database
      await RealtimeDatabaseService.saveTripStatus(
        userId: user.uid,
        status: 'completed',
        tripData: {
          'endTime': endTime.toIso8601String(),
          'duration': duration.inMinutes,
          'distance': distanceKm,
          'finalStatus': tripStatus,
        },
      );

      setState(() {
        isTripActive = false;
        drivingStatus = DrivingStatus.normal;
        startTime = null;
        startPosition = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje finalizado y guardado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtener string del estado del viaje
  String _getTripStatusString() {
    switch (drivingStatus) {
      case DrivingStatus.danger:
        return 'danger';
      case DrivingStatus.warning:
        return 'warning';
      case DrivingStatus.normal:
        return 'normal';
    }
  }

  /// Llamada de emergencia (911)
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes contacto de emergencia registrado'),
            ),
          );
        }
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
    
    // Obtener color e icono según estado
    final statusInfo = _getStatusInfo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroDrive'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          // Indicador de conexión ESP32
          if (lastTelemetryUpdate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: _ConnectionIndicator(
                  lastUpdate: lastTelemetryUpdate!,
                ),
              ),
            ),
          
          // Indicador de frecuencia cardíaca
          if (currentHeartRate > 0 && isTripActive)
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
                      Icon(
                        Icons.favorite,
                        color: _getHeartRateColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentHeartRate.toInt()} bpm',
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
      endDrawer: _buildDrawer(authProvider),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicadores de telemetría en tiempo real
            if (isTripActive && currentHeartRate > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TelemetryIndicator(
                      icon: handsOnWheel ? Icons.back_hand : Icons.warning,
                      label: handsOnWheel ? 'Manos OK' : 'Sin manos',
                      color: handsOnWheel ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 20),
                    _TelemetryIndicator(
                      icon: Icons.speed,
                      label: '${(accelX.abs() + accelY.abs()).toStringAsFixed(1)}g',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),

            // Indicador principal de estado
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: statusInfo.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusInfo.color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(statusInfo.icon, color: Colors.white, size: 70),
            ),
            const SizedBox(height: 20),
            Text(
              statusInfo.message,
              style: TextStyle(
                fontSize: 18,
                color: statusInfo.color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Botón de iniciar/finalizar viaje
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: isTripActive ? 55 : 70,
              width: isTripActive ? 200 : 250,
              child: ElevatedButton(
                onPressed: isTripActive ? _endTrip : _startTrip,
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
          FloatingActionButton.extended(
            heroTag: 'emergency',
            onPressed: _handleEmergencyCall,
            label: const Text('SOS 911'),
            icon: const Icon(Icons.emergency),
            backgroundColor: Colors.red.shade600,
          ),
          const SizedBox(height: 12),
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
              onPressed: () => Navigator.pushNamed(context, '/history'),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }

  /// Construir drawer
  Widget _buildDrawer(AppAuthProvider authProvider) {
    return Drawer(
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
    );
  }

  /// Obtener información del estado actual
  _StatusInfo _getStatusInfo() {
    switch (drivingStatus) {
      case DrivingStatus.danger:
        return _StatusInfo(
          color: Colors.red.shade600,
          icon: Icons.warning_rounded,
          message: 'Conducción peligrosa, ¡Detente!',
        );
      case DrivingStatus.warning:
        return _StatusInfo(
          color: Colors.amber.shade600,
          icon: Icons.error_outline,
          message: 'Conducción temerosa, ¡Descansa!',
        );
      case DrivingStatus.normal:
        return _StatusInfo(
          color: Colors.green.shade600,
          icon: Icons.check_circle_outline,
          message: 'Conducción excelente, ¡Sigue así!',
        );
    }
  }

  /// Obtener color de frecuencia cardíaca
  Color _getHeartRateColor() {
    if (currentHeartRate < 50 || currentHeartRate > 120) {
      return Colors.red;
    } else if (currentHeartRate < 60 || currentHeartRate > 100) {
      return Colors.orange;
    }
    return Colors.pink.shade200;
  }
}

// Enums y clases auxiliares
enum DrivingStatus { normal, warning, danger }

class _StatusInfo {
  final Color color;
  final IconData icon;
  final String message;

  _StatusInfo({
    required this.color,
    required this.icon,
    required this.message,
  });
}

// Widget indicador de telemetría
class _TelemetryIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TelemetryIndicator({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget indicador de conexión
class _ConnectionIndicator extends StatelessWidget {
  final DateTime lastUpdate;

  const _ConnectionIndicator({required this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    final secondsAgo = DateTime.now().difference(lastUpdate).inSeconds;
    final isConnected = secondsAgo < 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'ESP32' : 'Descon.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}