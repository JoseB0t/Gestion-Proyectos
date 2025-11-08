import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neurodrive/data/models/telemetry_model.dart';

class HeartRateChartWidget extends StatefulWidget {
  final String userId;
  final int dataPointsLimit;

  const HeartRateChartWidget({
    super.key,
    required this.userId,
    this.dataPointsLimit = 20,
  });

  @override
  State<HeartRateChartWidget> createState() => _HeartRateChartWidgetState();
}

class _HeartRateChartWidgetState extends State<HeartRateChartWidget> {
  List<TelemetryModel> telemetryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTelemetryData();
  }

  Future<void> _loadTelemetryData() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('telemetry')
          .orderBy('timestamp', descending: false)
          .limit(widget.dataPointsLimit)
          .get();

      final data = snapshot.docs
          .map((doc) => TelemetryModel.fromJson(doc.data()))
          .toList();

      setState(() {
        telemetryData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Frecuencia Cardíaca',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTelemetryData,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Últimas ${widget.dataPointsLimit} lecturas',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Gráfico
            SizedBox(
              height: 250,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : telemetryData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.show_chart,
                                  size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No hay datos disponibles',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildChart(),
            ),

            // Leyenda
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Preparar datos para el gráfico
    final spots = telemetryData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data.heartRate);
    }).toList();

    // Calcular min y max para el eje Y
    final heartRates = telemetryData.map((e) => e.heartRate).toList();
    final minY = (heartRates.reduce((a, b) => a < b ? a : b) - 10).clamp(40.0, 200.0);
    final maxY = (heartRates.reduce((a, b) => a > b ? a : b) + 10).clamp(40.0, 200.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= telemetryData.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (telemetryData.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final heartRate = telemetryData[index].heartRate;
                Color color = Colors.green;
                if (heartRate < 60 || heartRate > 100) {
                  color = Colors.orange;
                }
                if (heartRate < 50 || heartRate > 120) {
                  color = Colors.red;
                }
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.3),
                  Colors.red.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final index = flSpot.x.toInt();
                if (index >= telemetryData.length) return null;

                final data = telemetryData[index];
                final time = data.timestamp;
                final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

                return LineTooltipItem(
                  '$timeStr\n${flSpot.y.toInt()} bpm',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _LegendItem(
          color: Colors.green,
          label: 'Normal (60-100)',
        ),
        _LegendItem(
          color: Colors.orange,
          label: 'Alerta',
        ),
        _LegendItem(
          color: Colors.red,
          label: 'Crítico',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}