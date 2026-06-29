import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pessoa.dart';
import 'notification_service.dart';

class AuthService {
  static const String baseUrl = "http://localhost:8000/Controller/CrudUsuario.php";
  static Pessoa? _usuarioLogado;

  // ignore: unnecessary_getters_setters
  static Pessoa? get usuarioLogado => _usuarioLogado;
  
  static set usuarioLogado(Pessoa? pessoa) {
    _usuarioLogado = pessoa;
  }

  static Future<bool> login(String email, String senha) async {
    try {
      final url = Uri.parse(
        '$baseUrl?oper=Login&ds_email=${Uri.encodeComponent(email)}&ds_senha=${Uri.encodeComponent(senha)}',
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

          // Salva o token FCM vinculado ao usuário
          if (_usuarioLogado != null) {
            await NotificationService.saveTokenForUser(_usuarioLogado!.idPessoa);
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

