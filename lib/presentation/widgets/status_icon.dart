import 'package:flutter/material.dart';
import 'package:neurodrive/core/theme/app_theme.dart';

class StatusIcon extends StatefulWidget {
  final String status;
  final double size;
  const StatusIcon({super.key, required this.status, this.size = 120});

  @override
  State<StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<StatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    if (s == 'normal') {
      return ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: Column(
          children: [
            CircleAvatar(radius: widget.size/4, backgroundColor: AppTheme.successGreen, child: const Icon(Icons.check, size: 40, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Conducción excelente', style: const TextStyle(color: AppTheme.successGreen)),
          ],
        ),
      );
    } else if (s == 'warning') {
      return ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: Column(
          children: [
            CircleAvatar(radius: widget.size/4, backgroundColor: AppTheme.warningYellow, child: const Icon(Icons.info_outline, size: 40, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Conducción temerosa', style: const TextStyle(color: AppTheme.warningYellow)),
          ],
        ),
      );
    } else {
      return ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: Column(
          children: [
            CircleAvatar(radius: widget.size/4, backgroundColor: AppTheme.dangerRed, child: const Icon(Icons.error_outline, size: 40, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Conducción peligrosa', style: const TextStyle(color: AppTheme.dangerRed)),
          ],
        ),
      );
    }
  }
}
