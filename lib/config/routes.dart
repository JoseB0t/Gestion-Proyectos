import 'package:flutter/material.dart';
import 'package:neurodrive/chat_screen.dart';
import 'package:neurodrive/main.dart';
import 'package:neurodrive/presentation/screens/auth/login_screen.dart';
import 'package:neurodrive/presentation/screens/auth/register_screen.dart';
import 'package:neurodrive/presentation/screens/home/home_screen.dart';
import 'package:neurodrive/presentation/screens/history/history_screen.dart';

// Importaciones admin
import 'package:neurodrive/presentation/screens/admin/dashboard_screen.dart';
import 'package:neurodrive/presentation/screens/admin/drivers_list_screen.dart';
import 'package:neurodrive/presentation/screens/admin/reports_screen.dart';
import 'package:neurodrive/presentation/screens/admin/notifications_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const StartScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const HomeScreen(),
  '/history': (context) => const HistoryScreen(),
  '/chat': (context) => const ChatScreen(),

  // Rutas de administrador
  '/admin-dashboard': (context) => const AdminDashboardScreen(),
  '/admin-drivers': (context) => const DriversListScreen(),
  '/admin-reports': (context) => const AdminReportsScreen(),
  '/admin-notifications': (context) => const AdminNotificationsScreen(),
};

// Clase helper para navegación basada en roles
class RoleBasedNavigation {
  static void navigateAfterLogin(BuildContext context, String role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  static List<NavigationItem> getNavigationItems(String role) {
    if (role == 'admin') {
      return [
        NavigationItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          route: '/admin-dashboard',
        ),
        NavigationItem(
          icon: Icons.people,
          label: 'Conductores',
          route: '/admin-drivers',
        ),
        NavigationItem(
          icon: Icons.report,
          label: 'Reportes',
          route: '/admin-reports',
        ),
        NavigationItem(
          icon: Icons.notifications,
          label: 'Notificaciones',
          route: '/admin-notifications',
        ),
      ];
    } else {
      return [
        NavigationItem(icon: Icons.home, label: 'Inicio', route: '/home'),
        NavigationItem(
          icon: Icons.history,
          label: 'Historial',
          route: '/history',
        ),
      ];
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
