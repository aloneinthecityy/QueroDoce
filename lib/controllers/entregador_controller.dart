import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/entregador.dart';

class EntregadorController {
  static const String baseUrl =
      "http://localhost:8000/Controller/CrudEntregador.php";

  /// Login do entregador usando o backend/PostgreSQL.
  ///
  /// Endpoint esperado:
  /// CrudEntregador.php?oper=Login
  /// Body: ds_email, ds_senha
  /// Retorno: dados como Map ou List com id_entregador, nm_entregador etc.
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
