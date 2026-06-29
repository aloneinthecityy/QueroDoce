import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.showOrUpdatePedidoNotification(message);
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const int _pedidoNotificationId = 42;
  static const int _pedidoOngoingNotificationId = 99;

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final pedidoId = initialMessage.data['pedidoId'];
      if (pedidoId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            '/acompanhamento',
            arguments: pedidoId,
          );
        });
      }
    }
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

    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      'orders_ongoing_channel',
      'Pedido em andamento',
      description: 'Notificação ativa enquanto seu pedido está a caminho',
      importance: Importance.low,
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
    final status = message.data['status'];

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

  static Future<void> mostrarNotificacaoPersistente({
    required String titulo,
    required String corpo,
  }) async {
    await _localNotifications.show(
      _pedidoOngoingNotificationId,
      titulo,
      corpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders_ongoing_channel',
          'Pedido em andamento',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
        ),
      ),
    );
  }

  static Future<void> cancelarNotificacaoPersistente() async {
    await _localNotifications.cancel(_pedidoOngoingNotificationId);
  }

  static void _onForegroundMessage(RemoteMessage message) {
    showOrUpdatePedidoNotification(message);
  }

  static void _onNotificationOpened(RemoteMessage message) {
    final pedidoId = message.data['pedidoId'];
    if (pedidoId != null) {
      navigatorKey.currentState?.pushNamed('/acompanhamento', arguments: pedidoId);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final pedidoId = response.payload;
    if (pedidoId != null) {
      navigatorKey.currentState?.pushNamed('/acompanhamento', arguments: pedidoId);
    }
  }
}