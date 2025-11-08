import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// NOTA: Este archivo debe guardarse en: lib/data/services/notification_service.dart

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// Mostrar notificación local crítica
  static Future<void> showCriticalAlert({
    required String title,
    required String body,
    required int id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'critical_alerts',
      'Alertas Críticas',
      channelDescription: 'Notificaciones de seguridad críticas',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  /// Mostrar banner flotante en la app (in-app notification)
  static void showInAppBanner(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
    );
  }

  /// Mostrar diálogo modal crítico (bloquea la UI)
  static Future<void> showCriticalDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.danger:
        return Colors.red.shade600;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.info:
        return Colors.blue.shade600;
      case NotificationType.success:
        return Colors.green.shade600;
    }
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.danger:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
    }
  }
}

enum NotificationType {
  danger,
  warning,
  info,
  success,
}