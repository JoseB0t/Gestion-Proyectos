import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializar FCM
  static Future<void> initialize() async {
    // Solicitar permisos
    await _requestPermission();

    // Configurar notificaciones locales
    await _setupLocalNotifications();

    // Obtener token FCM y guardarlo
    await _saveFCMToken();

    // Manejar mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando el usuario toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar si la app se abrió desde una notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Solicitar permisos de notificación
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Usuario autorizó notificaciones');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Usuario autorizó notificaciones provisionales');
    } else {
      print('❌ Usuario denegó notificaciones');
    }
  }

  /// Configurar notificaciones locales
  static Future<void> _setupLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Obtener y guardar token FCM en Firestore
  static Future<void> _saveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      final user = FirebaseAuth.instance.currentUser;

      if (token != null && user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Token FCM guardado: $token');
      }
    } catch (e) {
      print('❌ Error guardando token FCM: $e');
    }

    // Refrescar token cuando cambie
    _messaging.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Manejar mensaje cuando la app está en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Mensaje recibido en primer plano: ${message.notification?.title}');

    // Mostrar notificación local
    _showLocalNotification(message);
  }

  /// Mostrar notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'neurodrive_alerts', // channelId
      'Alertas de Conducción', // channelName
      channelDescription: 'Notificaciones importantes sobre tu conducción',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'NeuroDrive',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// Manejar cuando el usuario toca una notificación
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('📬 Usuario abrió notificación: ${message.notification?.title}');
    
    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'alert':
          // Navegar a historial de alertas
          break;
        case 'trip':
          // Navegar a detalle del viaje
          break;
      }
    }
  }

  /// Callback cuando se toca una notificación local
  static void _onNotificationTap(NotificationResponse response) {
    print('👆 Usuario tocó notificación local: ${response.payload}');
  }

  /// Enviar notificación a un usuario específico (desde admin)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtener el token FCM del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('❌ Usuario no tiene token FCM');
        return;
      }

      // Guardar notificación en Firestore para que Cloud Function la procese
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'to': fcmToken,
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Notificación programada para envío');
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  /// Suscribirse a topic (para notificaciones masivas)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('✅ Suscrito al topic: $topic');
  }

  /// Desuscribirse de topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('❌ Desuscrito del topic: $topic');
  }
}

// Handler para mensajes en segundo plano (debe estar en nivel superior)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Mensaje en segundo plano: ${message.notification?.title}');
}