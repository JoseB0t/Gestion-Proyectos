import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/data/services/notification_service.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';
import 'package:neurodrive/data/services/esp_service.dart';
import 'package:neurodrive/data/services/call_service.dart';

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
  
  // Suscripción a lecturas del ESP32 en tiempo real
  StreamSubscription<DatabaseEvent>? _esp32Subscription;
  
  // Datos de sensores actuales (del ESP32)
  int heartRate = 0;
  bool handsOnWheel = false;
  int accelX = 0;
  int accelY = 0;
  int accelZ = 0;
  int fuerza = 0;
  DateTime? lastUpdate;
  
  // Estado de conducción calculado
  DrivingStatus drivingStatus = DrivingStatus.normal;
  
  // Control de alertas (evitar spam)
  DateTime? _lastHeartRateAlert;
  DateTime? _lastHandsAlert;
  DateTime? _lastMovementAlert;
  final Duration _alertCooldown = const Duration(seconds: 30);

  // NUEVO: Controlador de animación para evitar latencia
  late AnimationController _statusAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeESP32Connection();
    _startListeningToESP32();
    // Solicitar permisos de llamada al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallService.requestPhonePermission(context);
    });
  }

  @override
  void dispose() {
    _esp32Subscription?.cancel();
    super.dispose();
  }

  /// Inicializar conexión con ESP32
  Future<void> _initializeESP32Connection() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Enviar UID al ESP32 para que sepa dónde guardar datos
    await ESPService.enviarUidAlESP(userId);
  }

  /// Escuchar lecturas del ESP32 en tiempo real
  void _startListeningToESP32() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final database = FirebaseDatabase.instance;
    final lecturasRef = database.ref('users/$userId/lecturas');

    // OPTIMIZACIÓN: Escuchar cambios en tiempo real sin limitación
    _esp32Subscription = lecturasRef.onChildAdded.listen((DatabaseEvent event) {
      if (event.snapshot.value == null) return;

      try {
        final lectura = event.snapshot.value as Map<dynamic, dynamic>;

        // Actualizar estado inmediatamente sin setState para evitar rebuilds
        heartRate = lectura['bpm'] as int? ?? 0;
        fuerza = lectura['fuerza'] as int? ?? 0;
        accelX = lectura['ax'] as int? ?? 0;
        accelY = lectura['ay'] as int? ?? 0;
        accelZ = lectura['az'] as int? ?? 0;
        
        // Detectar manos en el volante
        final touch1 = lectura['touch1'] as int? ?? 0;
        final touch2 = lectura['touch2'] as int? ?? 0;
        handsOnWheel = (touch1 == 1 && touch2 == 1) || fuerza > 10;
        
        lastUpdate = DateTime.now();

        // OPTIMIZACIÓN: Solo llamar setState cuando sea necesario
        if (mounted) {
          setState(() {});
          
          // Analizar estado de conducción
          _analyzeDrivingStatus();
          
          // Verificar alertas solo si hay viaje activo
          if (isTripActive) {
            _checkAlerts();
          }
        }
      } catch (e) {
        debugPrint('❌ Error parseando datos del ESP32: $e');
      }
    });
  }

  /// Analizar estado de conducción basado en sensores
  void _analyzeDrivingStatus() {
    DrivingStatus newStatus = DrivingStatus.normal;
    
    // Calcular movimiento brusco (aceleración total)
    final movimientoTotal = (accelX.abs() + accelY.abs()) / 1000.0;
    
    // Condiciones de peligro
    final bool heartRateCritical = heartRate > 120 || (heartRate > 0 && heartRate < 50);
    final bool heartRateHigh = heartRate > 100 || (heartRate > 0 && heartRate < 60);
    final bool harshMovement = movimientoTotal > 3.0;
    final bool noHands = !handsOnWheel;
    
    // Determinar estado
    if (heartRateCritical || (harshMovement && noHands)) {
      newStatus = DrivingStatus.danger;
    } else if (heartRateHigh || harshMovement || noHands) {
      newStatus = DrivingStatus.warning;
    }
    
    // OPTIMIZACIÓN: Solo actualizar si el estado cambió
    if (drivingStatus != newStatus && mounted) {
      setState(() {
        drivingStatus = newStatus;
      });
    }
  }

  /// Verificar y mostrar alertas
  void _checkAlerts() {
    final now = DateTime.now();
    
    // Alerta de frecuencia cardíaca
    if (heartRate > 0) {
      if (heartRate < 50 || heartRate > 120) {
        if (_lastHeartRateAlert == null || 
            now.difference(_lastHeartRateAlert!) > _alertCooldown) {
          _showHeartRateAlert(critical: true);
          _lastHeartRateAlert = now;
        }
      } else if (heartRate < 60 || heartRate > 100) {
        if (_lastHeartRateAlert == null || 
            now.difference(_lastHeartRateAlert!) > _alertCooldown) {
          _showHeartRateAlert(critical: false);
          _lastHeartRateAlert = now;
        }
      }
    }

    // Alerta de manos fuera del volante
    if (!handsOnWheel) {
      if (_lastHandsAlert == null || 
          now.difference(_lastHandsAlert!) > const Duration(seconds: 10)) {
        _showHandsAlert();
        _lastHandsAlert = now;
      }
    }

    // Alerta de movimiento brusco
    final movimientoTotal = (accelX.abs() + accelY.abs()) / 1000.0;
    if (movimientoTotal > 3.0) {
      if (_lastMovementAlert == null || 
          now.difference(_lastMovementAlert!) > const Duration(seconds: 20)) {
        _showMovementAlert();
        _lastMovementAlert = now;
      }
    }
  }

  void _showHeartRateAlert({required bool critical}) {
    NotificationService.showCriticalAlert(
      title: critical ? '🚨 ALERTA CRÍTICA' : '⚠️ Atención',
      body: critical
          ? 'Frecuencia cardíaca: $heartRate bpm. Detente inmediatamente.'
          : 'Frecuencia cardíaca: $heartRate bpm. Considera descansar.',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
    if (critical && mounted) {
      NotificationService.showCriticalDialog(
        context,
        title: '🚨 ALERTA CRÍTICA',
        message: 'Tu frecuencia cardíaca está en $heartRate bpm. Detente ahora.',
      );
    }
  }

  void _showHandsAlert() {
    NotificationService.showCriticalAlert(
      title: '✋ Manos en el Volante',
      body: 'Por favor, coloca ambas manos en el volante',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  void _showMovementAlert() {
    NotificationService.showCriticalAlert(
      title: '🚗 Movimiento Brusco',
      body: 'Conduce con más suavidad',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> _startTrip() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activa la ubicación')),
          );
        }
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
        drivingStatus = DrivingStatus.normal;
      });

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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endTrip() async {
    if (startTime == null || startPosition == null) return;

    try {
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
      if (user == null) return;

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
        'status': _getStatusString(),
        'avgHeartRate': heartRate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        isTripActive = false;
        drivingStatus = DrivingStatus.normal;
        startTime = null;
        startPosition = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje finalizado y guardado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getStatusString() {
    switch (drivingStatus) {
      case DrivingStatus.danger:
        return 'danger';
      case DrivingStatus.warning:
        return 'warning';
      case DrivingStatus.normal:
        return 'normal';
    }
  }

  Future<void> _handleEmergencyCall() async {
    try {
      await CallService.callEmergency();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleEmergencyContactCall() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final emergencyContact = authProvider.user?.emergencyContact ?? '';
      
      if (emergencyContact.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes contacto de emergencia configurado'),
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
    final statusInfo = _getStatusInfo();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('NeuroDrive', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        actions: [
          // Indicador de conexión ESP32
          if (lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: _ConnectionIndicator(lastUpdate: lastUpdate!),
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
      body: SafeArea(
        child: Column(
          children: [
            // Banner de frecuencia cardíaca
            if (heartRate > 0 && isTripActive)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200), // OPTIMIZADO
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // OPTIMIZADO: Icono animado sin latencia
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.favorite,
                        key: ValueKey(heartRate),
                        color: _getHeartRateColor(),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OPTIMIZADO: Texto animado
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          child: Text('$heartRate BPM'),
                        ),
                        Text(
                          _getHeartRateStatus(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Indicadores de sensores - OPTIMIZADOS (solo cuando hay viaje activo)
                    if (isTripActive && heartRate > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // OPTIMIZADO: Cambio instantáneo de sensor
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: _SensorIndicator(
                                key: ValueKey(handsOnWheel),
                                icon: handsOnWheel ? Icons.back_hand : Icons.warning,
                                label: handsOnWheel ? 'Manos OK' : 'Sin manos',
                                color: handsOnWheel ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: _SensorIndicator(
                                key: ValueKey(fuerza),
                                icon: Icons.compress,
                                label: 'Fuerza: $fuerza%',
                                color: fuerza > 50 ? Colors.orange : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Logo o estado según si hay viaje activo
                    if (!isTripActive)
                      // Logo cuando NO hay viaje activo
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 80,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NeuroDrive',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Círculo de estado - OPTIMIZADO (solo cuando hay viaje activo)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: statusInfo.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusInfo.color.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            statusInfo.icon,
                            key: ValueKey(statusInfo.icon),
                            color: Colors.white,
                            size: 90,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Mensaje de estado - OPTIMIZADO (solo cuando hay viaje activo)
                    if (isTripActive)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusInfo.color.withOpacity(0.3)),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 18,
                            color: statusInfo.color,
                            fontWeight: FontWeight.w600,
                          ),
                          child: Text(
                            statusInfo.message,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      // Mensaje de bienvenida cuando NO hay viaje activo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Presiona "Iniciar viaje" para comenzar',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    const SizedBox(height: 40),

                    // Botón de viaje
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isTripActive ? _endTrip : _startTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTripActive ? Colors.red : AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isTripActive ? Icons.stop_circle : Icons.play_circle_filled,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isTripActive ? "Finalizar viaje" : "Iniciar viaje",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Botones de emergencia
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleEmergencyCall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.emergency, size: 32, color: Colors.white),
                                SizedBox(height: 8),
                                Text('SOS 123', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleEmergencyContactCall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.phone, size: 32, color: Colors.white),
                                SizedBox(height: 8),
                                Text('Contacto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppTheme.primaryBlue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        ],
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/chat');
          if (index == 2) Navigator.pushNamed(context, '/history');
        },
      ),
    );
  }

  Widget _buildDrawer(AppAuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.user?.name ?? 'Usuario',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    switch (drivingStatus) {
      case DrivingStatus.danger:
        return _StatusInfo(color: Colors.red.shade600, icon: Icons.warning_rounded, message: '¡Peligro! Detente');
      case DrivingStatus.warning:
        return _StatusInfo(color: Colors.amber.shade600, icon: Icons.error_outline, message: 'Conduce con precaución');
      case DrivingStatus.normal:
        return _StatusInfo(color: Colors.green.shade600, icon: Icons.check_circle_outline, message: '¡Excelente conducción!');
    }
  }

  Color _getHeartRateColor() {
    if (heartRate < 50 || heartRate > 120) return Colors.red;
    if (heartRate < 60 || heartRate > 100) return Colors.orange;
    return Colors.greenAccent;
  }

  String _getHeartRateStatus() {
    if (heartRate < 50) return 'Muy baja';
    if (heartRate < 60) return 'Baja';
    if (heartRate > 120) return 'Muy alta';
    if (heartRate > 100) return 'Alta';
    return 'Normal';
  }
}

// Enums y widgets auxiliares
enum DrivingStatus { normal, warning, danger }

class _StatusInfo {
  final Color color;
  final IconData icon;
  final String message;
  _StatusInfo({required this.color, required this.icon, required this.message});
}

class _SensorIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SensorIndicator({super.key, required this.icon, required this.label, required this.color});

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

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
          Icon(isConnected ? Icons.wifi : Icons.wifi_off, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'ESP32' : 'Descon.',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}