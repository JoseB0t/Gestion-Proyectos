import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
      ],
      selectedItemColor: AppTheme.primaryBlue,
      unselectedItemColor: Colors.grey,
    );
  }
}
