import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pessoa.dart';

class AuthService {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudUsuario.php";
  static Pessoa? _usuarioLogado;

  static Pessoa? get usuarioLogado => _usuarioLogado;

  static Future<bool> login(String email, String senha) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Login&ds_email=$email&ds_senha=$senha");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["Mensagem"] == "Login permitido" && data['dados'] != null) {
          if (data['dados'] is List && (data['dados'] as List).isNotEmpty) {
            _usuarioLogado = Pessoa.fromJson(data['dados'][0]);
          } else if (data['dados'] is Map) {
            _usuarioLogado = Pessoa.fromJson(data['dados']);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static void logout() {
    _usuarioLogado = null;
  }

  static bool get isLoggedIn => _usuarioLogado != null;
}

