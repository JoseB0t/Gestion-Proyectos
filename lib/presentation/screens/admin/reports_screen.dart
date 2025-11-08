import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String reportType = 'all'; // all, trips, alerts, users
  bool isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Análisis'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Generar Reporte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exporta datos y genera análisis detallados',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Selector de rango de fechas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rango de Fechas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: 'Fecha Inicio',
                            date: startDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateButton(
                            label: 'Fecha Fin',
                            date: endDate,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _setDateRange(7),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Última semana'),
                        ),
                        TextButton.icon(
                          onPressed: () => _setDateRange(30),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text('Último mes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tipo de reporte
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Reporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: reportType == 'all',
                          onSelected: (_) => setState(() => reportType = 'all'),
                        ),
                        ChoiceChip(
                          label: const Text('Viajes'),
                          selected: reportType == 'trips',
                          onSelected: (_) => setState(() => reportType = 'trips'),
                        ),
                        ChoiceChip(
                          label: const Text('Alertas'),
                          selected: reportType == 'alerts',
                          onSelected: (_) => setState(() => reportType = 'alerts'),
                        ),
                        ChoiceChip(
                          label: const Text('Usuarios'),
                          selected: reportType == 'users',
                          onSelected: (_) => setState(() => reportType = 'users'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isGenerating ? null : _generateReport,
                    icon: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.file_download),
                    label: Text(
                      isGenerating ? 'Generando...' : 'Generar Reporte',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isGenerating ? null : _exportToCSV,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Exportar CSV'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isGenerating ? null : _exportToJSON,
                    icon: const Icon(Icons.code),
                    label: const Text('Exportar JSON'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Estadísticas rápidas
            const Text(
              'Vista Rápida',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  // Seleccionar fecha
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  // Establecer rango de fechas predefinido
  void _setDateRange(int days) {
    setState(() {
      endDate = DateTime.now();
      startDate = DateTime.now().subtract(Duration(days: days));
    });
  }

  // Generar reporte
  Future<void> _generateReport() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rango de fechas'),
        ),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final data = await _fetchReportData();
      
      // Mostrar resumen
      await _showReportSummary(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Obtener datos del reporte
  Future<Map<String, dynamic>> _fetchReportData() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();

    int totalTrips = 0;
    int totalAlerts = 0;
    double totalDistance = 0;

    for (var userDoc in usersSnapshot.docs) {
      // Obtener viajes en el rango
      final tripsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('trips')
          .where('startTime', isGreaterThanOrEqualTo: startDate)
          .where('startTime', isLessThanOrEqualTo: endDate)
          .get();

      totalTrips += tripsQuery.docs.length;

      for (var trip in tripsQuery.docs) {
        final data = trip.data();
        final distanceStr = data['distance'] ?? '0 km';
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(distanceStr);
        if (match != null) {
          totalDistance += double.parse(match.group(1)!);
        }
      }

      // Obtener alertas
      final alertsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('telemetry')
          .where('timestamp', isGreaterThanOrEqualTo: startDate!.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate!.toIso8601String())
          .get();

      for (var doc in alertsQuery.docs) {
        final data = doc.data();
        final heartRate = (data['heart_rate'] as num?)?.toDouble() ?? 0;
        if (heartRate > 100 || heartRate < 60) {
          totalAlerts++;
        }
      }
    }

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalTrips': totalTrips,
      'totalAlerts': totalAlerts,
      'totalDistance': totalDistance,
      'averageTripsPerUser': totalTrips / usersSnapshot.docs.length,
    };
  }

  // Mostrar resumen del reporte
  Future<void> _showReportSummary(Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen del Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 Periodo: ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'),
            const SizedBox(height: 16),
            _SummaryRow('Conductores', '${data['totalUsers']}'),
            _SummaryRow('Total Viajes', '${data['totalTrips']}'),
            _SummaryRow('Total Alertas', '${data['totalAlerts']}'),
            _SummaryRow('Distancia Total', '${data['totalDistance'].toStringAsFixed(1)} km'),
            _SummaryRow('Promedio Viajes/Usuario', '${data['averageTripsPerUser'].toStringAsFixed(1)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Exportar a CSV
  Future<void> _exportToCSV() async {
    setState(() => isGenerating = true);

    try {
      final data = await _fetchReportData();
      final csv = _generateCSV(data);
      
      // En una app real, aquí usarías un plugin como path_provider
      // para guardar el archivo. Por ahora solo mostramos un mensaje.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV generado (implementar guardado)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Generar contenido CSV
  String _generateCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('Métrica,Valor');
    buffer.writeln('Total Conductores,${data['totalUsers']}');
    buffer.writeln('Total Viajes,${data['totalTrips']}');
    buffer.writeln('Total Alertas,${data['totalAlerts']}');
    buffer.writeln('Distancia Total (km),${data['totalDistance']}');
    return buffer.toString();
  }

  // Exportar a JSON
  Future<void> _exportToJSON() async {
    setState(() => isGenerating = true);

    try {
      final data = await _fetchReportData();
      final jsonStr = jsonEncode(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON generado (implementar guardado)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Vista rápida de estadísticas
  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchReportData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Text('No hay datos disponibles');
        }

        final data = snapshot.data!;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _QuickStatCard(
              icon: Icons.people,
              label: 'Conductores',
              value: '${data['totalUsers']}',
              color: Colors.blue,
            ),
            _QuickStatCard(
              icon: Icons.route,
              label: 'Viajes',
              value: '${data['totalTrips']}',
              color: Colors.green,
            ),
            _QuickStatCard(
              icon: Icons.warning,
              label: 'Alertas',
              value: '${data['totalAlerts']}',
              color: Colors.orange,
            ),
            _QuickStatCard(
              icon: Icons.map,
              label: 'Distancia',
              value: '${data['totalDistance'].toStringAsFixed(0)} km',
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }
}

// Widgets auxiliares
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date!)
                      : 'Seleccionar',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
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