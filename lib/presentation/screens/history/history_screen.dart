import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> dummyTrips = [
    {
      "title": "Viaje 1",
      "date": "2024-06-01",
      "duration": "30 min",
      "distance": "15 km",
      "rating": "Mala",
    },
    {
      "title": "Viaje 2",
      "date": "2024-06-02",
      "duration": "45 min",
      "distance": "22 km",
      "rating": "Excelente",
    },
    {
      "title": "Viaje 3",
      "date": "2024-06-03",
      "duration": "20 min",
      "distance": "10 km",
      "rating": "Regular",
    },
  ];

  Color _getColor(String rating) {
    switch (rating) {
      case "Excelente":
        return Colors.green.shade600;
      case "Regular":
        return Colors.orange.shade700;
      case "Mala":
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String rating) {
    switch (rating) {
      case "Excelente":
        return Icons.check_circle_outline;
      case "Regular":
        return Icons.error_outline;
      case "Mala":
        return Icons.warning_rounded;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Viajes"),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyTrips.length,
        itemBuilder: (context, index) {
          final trip = dummyTrips[index];
          final color = _getColor(trip["rating"]);
          final icon = _getIcon(trip["rating"]);

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
            child: GestureDetector(
              onTap: () {
                // Podrías abrir detalles del viaje
              },
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
                              trip["title"],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Fecha: ${trip["date"]}"),
                            Text("Duración: ${trip["duration"]}"),
                            Text("Distancia: ${trip["distance"]}"),
                            const SizedBox(height: 4),
                            Text(
                              "Calificación: ${trip["rating"]}",
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
            ),
          );
        },
      ),
    );
  }
}
