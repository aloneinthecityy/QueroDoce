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

  static Future<Map<String, dynamic>?> esqueceuSenha(String email) async {
    try {
      final url = Uri.parse("$baseUrl?oper=EsqueceuSenha&ds_email=${Uri.encodeComponent(email)}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Mensagem'] != null && data['Mensagem'].toString().contains('sucesso')) {
          return data['dados'] != null && data['dados'] is Map ? data['dados'] : null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> atualizarDados(Pessoa pessoa, {String? novaSenha}) async {
    try {
      // Constrói a URL base
      // NOTA: ds_complemento não é enviado - o campo de rua/logradouro é apenas para exibição
      String url = "$baseUrl?oper=Alterar"
          "&id_pessoa=${pessoa.idPessoa}"
          "&nm_pessoa=${Uri.encodeComponent(pessoa.nmPessoa)}"
          "&nu_cpf=${pessoa.nuCpf}"
          "&nu_cel=${pessoa.nuCel}"
          "&ds_email=${Uri.encodeComponent(pessoa.dsEmail)}"
          "&nu_cep=${pessoa.nuCep}"
          "&ds_complemento=" // Envia vazio - não atualiza o campo de rua/logradouro
          "&nu_endereco=${pessoa.nuEndereco ?? 0}";
      
      // Só adiciona senha se foi fornecida
      if (novaSenha != null && novaSenha.isNotEmpty) {
        url += "&ds_senha=${Uri.encodeComponent(novaSenha)}";
      }
      
      final response = await http.get(Uri.parse(url));

      print('DEBUG - URL atualização: $url');
      print('DEBUG - Status code: ${response.statusCode}');
      print('DEBUG - Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          print('DEBUG - Resposta vazia do servidor');
          return false;
        }
        
        final data = json.decode(responseBody);
        print('DEBUG - Dados decodificados: $data');
        
        // Verifica se a mensagem contém sucesso
        final mensagem = data['Mensagem']?.toString() ?? '';
        final sucesso = mensagem.contains('Alterados') || 
                       mensagem.contains('alterados') ||
                       mensagem.contains('sucesso') ||
                       data['NumMens'] == 1;
        
        print('DEBUG - Mensagem: $mensagem');
        print('DEBUG - Sucesso: $sucesso');
        
        return sucesso;
      }
      return false;
    } catch (e) {
      print('DEBUG - Erro ao atualizar dados: $e');
      return false;
    }
  }
}

