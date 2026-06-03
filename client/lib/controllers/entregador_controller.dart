import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entregador.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EntregadorController {
  static const String baseUrl = "http://localhost/backend/Controller/CrudEntregador.php";

  static const Map<String, Map<String, String>> _mensagens = {
    'aceito': {
      'titulo': 'Pedido confirmado! 🎉',
      'mensagem': 'Um entregador aceitou seu pedido e está indo para a loja!',
    },
    'coletando': {
      'titulo': 'Entregador na loja! 🏪',
      'mensagem': 'Seu entregador chegou à loja e está retirando seus doces!',
    },
    'em_entrega': {
      'titulo': 'Pedido a caminho! 🛵',
      'mensagem': 'Seu pedido saiu para entrega! Toque para acompanhar no mapa.',
    },
    'entregue': {
      'titulo': 'Pedido entregue! 🍰',
      'mensagem': 'Bom apetite! Obrigado por escolher o QueroDoce.',
    },
  };

  static Future<Entregador?> login(String email, String senha) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Login");
      final response = await http.post(
        url,
        body: {'ds_email': email, 'ds_senha': senha},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entregadorData = _extractEntregadorData(data);
        if (entregadorData != null) return Entregador.fromJson(entregadorData);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> notificarCliente({
    required String pedidoDocId,
    required String novoStatus,
    required FirebaseFirestore firestore,
  }) async {
    final msg = _mensagens[novoStatus];
    if (msg == null) return;

    try {
      final pedidoDoc = await firestore
          .collection('pedidos')
          .doc(pedidoDocId)
          .get();

      final idCliente = pedidoDoc.data()?['idCliente']?.toString();
      if (idCliente == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(idCliente)
          .get();

      final token = userDoc.data()?['fcmToken'];
      if (token == null) return;

      await http.post(
        Uri.parse('http://localhost/backend/Controller/EnviarNotificacao.php'),
        body: {
          'token': token,
          'titulo': msg['titulo']!,
          'mensagem': msg['mensagem']!,
          'pedidoId': pedidoDocId,
          'status': novoStatus,
        },
      );
    } catch (e) {
      debugPrint('Erro ao enviar notificação: $e');
    }
  }

  static Map<String, dynamic>? _extractEntregadorData(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return _asMap(data.first);
    }

    if (data is! Map) return null;

    final dados = data['dados'] ?? data['Dados'] ?? data['DADOS'];

    if (dados is List && dados.isNotEmpty) {
      return _asMap(dados.first);
    }

    if (dados is Map) {
      return _asMap(dados);
    }

    return _asMap(data);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }
}