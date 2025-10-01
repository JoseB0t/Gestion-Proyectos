import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreen();
}

class _HistoryScreen extends State<HistoryScreen> {
  int _selectedIndex = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        actions: [IconButton(icon: Icon(Icons.menu), onPressed: () {})],
      ),

      body: ListView(
        children: [
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viaje 1',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Fecha: 2024-06-01'),
                Text('Duración: 30 minutos'),
                Text('Distancia: 15 km'),
                Text(
                  'Calificación de conducción: Mala',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viaje 2',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Fecha: 2024-06-02'),
                Text('Duración: 45 minutos'),
                Text('Distancia: 22 km'),
                Text(
                  'Calificación de conducción: Excelente',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viaje 3',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Fecha: 2024-06-03'),
                Text('Duración: 20 minutos'),
                Text('Distancia: 10 km'),
                Text(
                  'Calificación de conducción: Regular',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Incio'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
