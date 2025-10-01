import 'package:flutter/material.dart';
import 'package:neurodrive/presentation/screens/auth/login_screen.dart';
import 'package:neurodrive/presentation/screens/history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> screens = [
    HistoryScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('NeuroDrive'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginScreen()));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            Text('Conducion excelente, !Sigue asi!', style: TextStyle(color: Colors.green)),
            Icon(Icons.info_rounded, size: 100, color: Colors.yellow),
            Text('Conducion temerosa, !Desacansa un poco!', style: TextStyle(color: Colors.yellow)),
            Icon(Icons.emergency_rounded, size: 100, color: Colors.red),
            Text('Conducion peligrosa, !Detente!', style: TextStyle(color: Colors.red))
        ]) 
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.sos),
      ),
      bottomNavigationBar: NavigationBar(destinations:  const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Incio'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
      ], selectedIndex: _selectedIndex,
      onDestinationSelected: (index){
        setState(() {
          _selectedIndex = index;
        });
      },),
    );
  }
}