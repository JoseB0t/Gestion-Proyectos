import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _getColor(String status) {
    switch (status) {
      case "Excelente":
      case "normal":
        return Colors.green.shade600;
      case "Regular":
      case "warning":
        return Colors.orange.shade700;
      case "Mala":
      case "danger":
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String status) {
    switch (status) {
      case "Excelente":
      case "normal":
        return Icons.check_circle_outline;
      case "Regular":
      case "warning":
        return Icons.error_outline;
      case "Mala":
      case "danger":
        return Icons.warning_rounded;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Viajes"),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: uid == null
          ? const Center(child: Text("Usuario no autenticado"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('trips')
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aún no hay viajes registrados",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final trips = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index].data() as Map<String, dynamic>;

                    final title = trip["title"] ?? "Viaje sin título";
                    final duration = trip["duration"] ?? "Sin duración";
                    final distance = trip["distance"] ?? "Sin distancia";
                    final status = trip["status"] ?? "Desconocido";
                    final startTime = (trip["startTime"] as Timestamp?)?.toDate();

                    final color = _getColor(status);
                    final icon = _getIcon(status);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                radius: 26,
                                child: Icon(icon, color: color, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (startTime != null)
                                      Text(
                                        "Fecha: ${startTime.day}/${startTime.month}/${startTime.year}",
                                      ),
                                    Text("Duración: $duration"),
                                    Text("Distancia: $distance"),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Estado: $status",
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
