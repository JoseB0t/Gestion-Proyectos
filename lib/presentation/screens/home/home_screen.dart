import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String drivingStatus = 'normal'; // normal, warning, danger
  bool isTripActive = false;

  DateTime? startTime;
  Position? startPosition;
  Timer? sensorTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    sensorTimer?.cancel();
    super.dispose();
  }

  // --- Simulación IA/sensores ---
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

  // --- Iniciar viaje ---
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

    // simular IA cada 3 segundos
    sensorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateDrivingStatus();
    });
  }

  // --- Finalizar viaje ---
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

  @override
  Widget build(BuildContext context) {
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
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFF0C3C78)),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                final userData =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? 'Usuario sin nombre';
                final email = userData['email'] ??
                    FirebaseAuth.instance.currentUser?.email ??
                    'Correo no disponible';

                return DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF0C3C78)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_circle,
                          size: 50, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                );
              },
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
                await FirebaseAuth.instance.signOut();
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

            // Botón de iniciar / finalizar viaje
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: isTripActive ? 55 : 70,
              width: isTripActive ? 200 : 250,
              child: ElevatedButton(
                onPressed: () {
                  isTripActive ? _endTrip() : _startTrip();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isTripActive ? Colors.red : AppTheme.primaryBlue,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('SOS'),
        icon: const Icon(Icons.emergency),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          ],
        ),
      ),
    );
  }
}
