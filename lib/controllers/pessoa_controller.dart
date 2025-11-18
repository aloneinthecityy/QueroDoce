import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pessoa.dart';

class PessoaController {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudUsuario.php";

  static Future<String?> buscarEndereco(int idPessoa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=BuscarEndereco&id_pessoa=$idPessoa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null) {
          if (data['dados'] is Map && data['dados']['endereco'] != null) {
            return data['dados']['endereco'];
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

