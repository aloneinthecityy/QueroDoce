import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Fora de qualquer classe, obrigatório pro background funcionar
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Registra o handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Pede permissão ao usuário
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 3. Cria canal de alta prioridade no Android (heads-up notification)
    await _createAndroidChannel();

    // 4. Configura notificações locais
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 5. Listeners
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
  }

  static Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      'orders_channel',
      'Pedidos',
      description: 'Atualizações do seu pedido',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders_channel',
          'Pedidos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data['orderId'],
    );
  }

  static void _onForegroundMessage(RemoteMessage message) {
    // FCM não exibe automaticamente quando o app está aberto
    showLocalNotification(message);
  }

  static void _onNotificationOpened(RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId != null) {
      // Navega para a tela do pedido — adapta pro seu sistema de rotas
      // GoRouter.of(context).go('/order/$orderId');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final orderId = response.payload;
    if (orderId != null) {
      // Mesma coisa aqui — navega pro pedido
    }
  }
}