import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HeartRateChartWidget extends StatefulWidget {
  final String userId;
  final int dataPointsLimit;

  const HeartRateChartWidget({
    super.key,
    required this.userId,
    this.dataPointsLimit = 30,
  });

  @override
  State<HeartRateChartWidget> createState() => _HeartRateChartWidgetState();
}

class _HeartRateChartWidgetState extends State<HeartRateChartWidget> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<FlSpot> _heartRateData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _minBpm = 40;
  double _maxBpm = 180;

  @override
  void initState() {
    super.initState();
    _listenToHeartRateData();
  }

  void _listenToHeartRateData() {
    final lecturasRef = _database.child('users/${widget.userId}/lecturas');

    lecturasRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      
      if (data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay datos de frecuencia cardíaca';
          _heartRateData = [];
        });
        return;
      }

      List<MapEntry<int, int>> readings = [];

      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final bpm = value['bpm'];
            final timestamp = value['timestamp_ms'];
            
            if (bpm != null && timestamp != null) {
              final bpmValue = bpm is int ? bpm : int.tryParse(bpm.toString()) ?? 0;
              final timestampValue = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
              
              // Solo agregar si BPM es válido (entre 40 y 200)
              if (bpmValue > 0 && bpmValue >= 40 && bpmValue <= 200) {
                readings.add(MapEntry(timestampValue, bpmValue));
              }
            }
          }
        });
      }

      // Ordenar por timestamp
      readings.sort((a, b) => a.key.compareTo(b.key));

      // Limitar cantidad de puntos
      if (readings.length > widget.dataPointsLimit) {
        readings = readings.sublist(readings.length - widget.dataPointsLimit);
      }

      if (readings.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay lecturas válidas de BPM';
          _heartRateData = [];
        });
        return;
      }

      // Convertir a FlSpot para el gráfico
      List<FlSpot> spots = [];
      for (int i = 0; i < readings.length; i++) {
        spots.add(FlSpot(i.toDouble(), readings[i].value.toDouble()));
      }

      // Calcular rango de BPM para escala del gráfico
      final bpmValues = readings.map((e) => e.value.toDouble()).toList();
      final minBpm = bpmValues.reduce((a, b) => a < b ? a : b);
      final maxBpm = bpmValues.reduce((a, b) => a > b ? a : b);

      setState(() {
        _heartRateData = spots;
        _isLoading = false;
        _errorMessage = '';
        _minBpm = (minBpm - 10).clamp(40, 200);
        _maxBpm = (maxBpm + 10).clamp(40, 200);
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $error';
      });
    });
  }

  Color _getHeartRateColor(double bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm >= 60 && bpm <= 100) return Colors.green;
    if (bpm > 100 && bpm <= 140) return Colors.orange;
    return Colors.red;
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
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Frecuencia Cardíaca',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_heartRateData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getHeartRateColor(_heartRateData.last.y).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getHeartRateColor(_heartRateData.last.y),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: _getHeartRateColor(_heartRateData.last.y),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_heartRateData.last.y.toInt()} BPM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getHeartRateColor(_heartRateData.last.y),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.heart_broken, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else if (_heartRateData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Esperando datos del sensor...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
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
                          interval: _heartRateData.length > 10 ? 5 : 2,
                          getTitlesWidget: (value, meta) {
                            if (value == _heartRateData.length - 1) {
                              return const Text(
                                'Ahora',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    minX: 0,
                    maxX: (_heartRateData.length - 1).toDouble(),
                    minY: _minBpm,
                    maxY: _maxBpm,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _heartRateData,
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade400,
                            Colors.pink.shade300,
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: _getHeartRateColor(spot.y),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400.withOpacity(0.3),
                              Colors.pink.shade300.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toInt()} BPM',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // Leyenda de zonas de frecuencia cardíaca
            if (_heartRateData.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildLegendItem(Colors.blue, 'Reposo (<60)', 60),
                  _buildLegendItem(Colors.green, 'Normal (60-100)', 100),
                  _buildLegendItem(Colors.orange, 'Elevada (100-140)', 140),
                  _buildLegendItem(Colors.red, 'Alta (>140)', 200),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double bpm) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}