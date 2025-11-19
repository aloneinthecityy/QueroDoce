import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pessoa.dart';

class AuthService {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudUsuario.php";
  static Pessoa? _usuarioLogado;

  static Pessoa? get usuarioLogado => _usuarioLogado;
  
  static set usuarioLogado(Pessoa? pessoa) {
    _usuarioLogado = pessoa;
  }

  static Future<bool> login(String email, String senha) async {
    try {
      final url = Uri.http(
        '200.19.1.19',
        '/usuario01/Controller/CrudUsuario.php',
        {
          'oper': 'Login',
          'ds_email': email,
          'ds_senha': senha,
        },
      );
      
      final response = await http.get(url);

      print('DEBUG AuthService - URL: $url');
      print('DEBUG AuthService - Status: ${response.statusCode}');
      print('DEBUG AuthService - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          print('DEBUG AuthService - Resposta vazia');
          return false;
        }
        
        final data = json.decode(responseBody);
        print('DEBUG AuthService - Dados: $data');
        
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
      print('DEBUG AuthService - Erro: $e');
      return false;
    }
  }

  static void logout() {
    _usuarioLogado = null;
  }

  static bool get isLoggedIn => _usuarioLogado != null;
}

