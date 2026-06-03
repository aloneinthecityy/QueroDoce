import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.showOrUpdatePedidoNotification(message);
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const int _pedidoNotificationId = 42;

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _createChannels();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
  }

  static Future<void> _createChannels() async {
    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      'orders_channel',
      'Pedidos',
      description: 'Atualizações do seu pedido',
      importance: Importance.max,
    ));
  }

  static Future<void> saveTokenForUser(int idPessoa) async {
    final token = await _messaging.getToken();
    print('🔑 FCM Token: $token');
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(idPessoa.toString())
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(idPessoa.toString())
          .update({'fcmToken': newToken});
    });
  }

  static Future<void> showOrUpdatePedidoNotification(RemoteMessage message) async {
    final titulo = message.notification?.title;
    final corpo = message.notification?.body;
    final pedidoId = message.data['pedidoId'];

    if (titulo == null || corpo == null) return;

    await _localNotifications.show(
      _pedidoNotificationId,
      titulo,
      corpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders_channel',
          'Pedidos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: pedidoId,
    );
  }

  static void _onForegroundMessage(RemoteMessage message) {
    showOrUpdatePedidoNotification(message);
  }

  static void _onNotificationOpened(RemoteMessage message) {
    final pedidoId = message.data['pedidoId'];
    if (pedidoId != null) {
      // navega para a tela do pedido
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final pedidoId = response.payload;
    if (pedidoId != null) {
      // navega para a tela do pedido
    }
  }
}