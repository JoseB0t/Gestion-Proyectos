import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:neurodrive/presentation/state/auth_provider.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => isLoading = true);

    try {
      // Obtener total de conductores
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      final totalDrivers = usersSnapshot.docs.length;

      // Obtener conductores activos hoy (con viajes)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      int activeDriversToday = 0;
      int totalTripsToday = 0;
      int totalAlertsToday = 0;

      for (var userDoc in usersSnapshot.docs) {
        // Contar viajes del día
        final tripsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('trips')
            .where('startTime', isGreaterThanOrEqualTo: startOfDay)
            .get();

        if (tripsSnapshot.docs.isNotEmpty) {
          activeDriversToday++;
          totalTripsToday += tripsSnapshot.docs.length;
        }

        // Contar alertas del día
        final telemetrySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('telemetry')
            .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .get();

        for (var doc in telemetrySnapshot.docs) {
          final data = doc.data();
          final heartRate = (data['heart_rate'] as num?)?.toDouble() ?? 0;
          final handsOnWheel = data['hands'] as bool? ?? true;

          if (heartRate > 100 || heartRate < 60 || !handsOnWheel) {
            totalAlertsToday++;
          }
        }
      }

      setState(() {
        stats = {
          'totalDrivers': totalDrivers,
          'activeToday': activeDriversToday,
          'tripsToday': totalTripsToday,
          'alertsToday': totalAlertsToday,
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando estadísticas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0C3C78)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.user?.name ?? 'Administrador',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    authProvider.user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Conductores'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin-drivers');
              },
            ),
            const Divider(),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de bienvenida
                    Text(
                      'Bienvenido, ${authProvider.user?.name?.split(' ').first ?? 'Admin'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resumen general del sistema',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Grid de estadísticas principales
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _StatCard(
                          title: 'Total Conductores',
                          value: '${stats['totalDrivers'] ?? 0}',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          title: 'Activos Hoy',
                          value: '${stats['activeToday'] ?? 0}',
                          icon: Icons.directions_car,
                          color: Colors.green,
                        ),
                        _StatCard(
                          title: 'Viajes Hoy',
                          value: '${stats['tripsToday'] ?? 0}',
                          icon: Icons.route,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          title: 'Alertas Hoy',
                          value: '${stats['alertsToday'] ?? 0}',
                          icon: Icons.warning_rounded,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Sección de acciones rápidas
                    Text(
                      'Acciones Rápidas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    _ActionButton(
                      icon: Icons.people,
                      title: 'Ver Todos los Conductores',
                      subtitle: 'Lista completa con filtros',
                      onTap: () => Navigator.pushNamed(context, '/admin-drivers'),
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.bar_chart,
                      title: 'Reportes Detallados',
                      subtitle: 'Análisis y estadísticas avanzadas',
                      onTap: () => Navigator.pushNamed(context, '/admin-reports'),
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.notifications_active,
                      title: 'Alertas Críticas',
                      subtitle: 'Ver historial de alertas',
                      onTap: () => Navigator.pushNamed(context, '/admin-notifications'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Widget de tarjeta de estadística
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de botón de acción
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}