import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String drivingStatus = 'normal'; // valor temporal para ejemplo

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
          )
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0C3C78)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_circle, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Conductor: Juan Pérez",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text("juan.perez@email.com",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
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
                  )
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
                onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.history),
                color: Colors.grey,
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                }),
          ],
        ),
      ),
    );
  }
}
