import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/presentation/widgets/heart_rate_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: const Text("Historial"),
        backgroundColor: AppTheme.primaryBlue,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: "Viajes"),
            Tab(icon: Icon(Icons.bar_chart), text: "Estadísticas"),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: Text("Usuario no autenticado"))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripsTab(uid),
                _buildStatsTab(uid),
              ],
            ),
    );
  }

  // Tab 1: Lista de viajes
  Widget _buildTripsTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "Aún no hay viajes registrados",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Inicia tu primer viaje desde el inicio",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
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
                child: InkWell(
                  onTap: () => _showTripDetails(context, trip, color, icon),
                  borderRadius: BorderRadius.circular(16),
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
                                  "📅 ${startTime.day}/${startTime.month}/${startTime.year} - ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(duration),
                                  const SizedBox(width: 16),
                                  Icon(Icons.route, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(distance),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color, width: 1),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Tab 2: Estadísticas
  Widget _buildStatsTab(String uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Tu Desempeño',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Análisis de tus viajes y monitoreo',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Estadísticas generales
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('trips')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay datos para mostrar'),
                  ),
                );
              }

              final trips = snapshot.data!.docs;
              final totalTrips = trips.length;

              // Calcular estadísticas
              int normalTrips = 0;
              int warningTrips = 0;
              int dangerTrips = 0;
              double totalDistanceKm = 0;
              int totalMinutes = 0;

              for (var doc in trips) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? '';
                
                if (status == 'normal' || status == 'Excelente') {
                  normalTrips++;
                } else if (status == 'warning' || status == 'Regular') {
                  warningTrips++;
                } else if (status == 'danger' || status == 'Mala') {
                  dangerTrips++;
                }

                // Extraer distancia (ej: "5.23 km")
                final distanceStr = data['distance'] ?? '0 km';
                final distanceMatch = RegExp(r'(\d+\.?\d*)').firstMatch(distanceStr);
                if (distanceMatch != null) {
                  totalDistanceKm += double.parse(distanceMatch.group(1)!);
                }

                // Extraer duración (ej: "15 min")
                final durationStr = data['duration'] ?? '0 min';
                final durationMatch = RegExp(r'(\d+)').firstMatch(durationStr);
                if (durationMatch != null) {
                  totalMinutes += int.parse(durationMatch.group(1)!);
                }
              }

              return Column(
                children: [
                  // Cards de resumen
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        icon: Icons.route,
                        title: 'Total Viajes',
                        value: '$totalTrips',
                        color: Colors.blue,
                      ),
                      _StatCard(
                        icon: Icons.check_circle,
                        title: 'Viajes Seguros',
                        value: '$normalTrips',
                        color: Colors.green,
                      ),
                      _StatCard(
                        icon: Icons.map,
                        title: 'Distancia',
                        value: '${totalDistanceKm.toStringAsFixed(1)} km',
                        color: Colors.orange,
                      ),
                      _StatCard(
                        icon: Icons.timer,
                        title: 'Tiempo Total',
                        value: '${(totalMinutes / 60).toStringAsFixed(1)} h',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gráfico de distribución de estados
                  if (totalTrips > 0) _buildStatusChart(normalTrips, warningTrips, dangerTrips),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Gráfico de frecuencia cardíaca
          HeartRateChartWidget(
            userId: uid,
            dataPointsLimit: 30,
          ),
        ],
      ),
    );
  }

  // Gráfico de distribución de estados
  Widget _buildStatusChart(int normal, int warning, int danger) {
    final total = normal + warning + danger;
    final normalPercent = (normal / total * 100).toInt();
    final warningPercent = (warning / total * 100).toInt();
    final dangerPercent = (danger / total * 100).toInt();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Distribución de Viajes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Barra de progreso visual
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: [
                    if (normal > 0)
                      Expanded(
                        flex: normal,
                        child: Container(color: Colors.green),
                      ),
                    if (warning > 0)
                      Expanded(
                        flex: warning,
                        child: Container(color: Colors.orange),
                      ),
                    if (danger > 0)
                      Expanded(
                        flex: danger,
                        child: Container(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Leyenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: Colors.green,
                  label: 'Seguros',
                  value: '$normal ($normalPercent%)',
                ),
                _LegendItem(
                  color: Colors.orange,
                  label: 'Precaución',
                  value: '$warning ($warningPercent%)',
                ),
                _LegendItem(
                  color: Colors.red,
                  label: 'Peligrosos',
                  value: '$danger ($dangerPercent%)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar detalles del viaje
  void _showTripDetails(BuildContext context, Map<String, dynamic> trip, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final startTime = (trip["startTime"] as Timestamp?)?.toDate();
          final endTime = (trip["endTime"] as Timestamp?)?.toDate();

          return Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Center(
                  child: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    radius: 40,
                    child: Icon(icon, color: color, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    trip["title"] ?? "Viaje",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Fecha de inicio',
                  value: startTime != null
                      ? '${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'
                      : 'N/A',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.timer,
                  label: 'Duración',
                  value: trip["duration"] ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.route,
                  label: 'Distancia',
                  value: trip["distance"] ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.info,
                  label: 'Estado',
                  value: trip["status"] ?? 'N/A',
                  valueColor: color,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget para tarjetas de estadísticas
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para leyenda
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Widget para filas de detalle
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}