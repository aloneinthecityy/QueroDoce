import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/carrinho_item.dart';

class CarrinhoController {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudCarrinho.php";

  static Future<bool> adicionarItem(int idPessoa, int idProduto, int quantidade) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Inserir&id_pessoa=$idPessoa&id_produto=$idProduto&nu_qtd=$quantidade");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Mensagem'] != null && data['Mensagem'].toString().contains('sucesso');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> alterarQuantidade(int idPessoa, int idProduto, int quantidade) async {
    try {
      final url = Uri.parse("$baseUrl?oper=AlterarQuantidade&id_pessoa=$idPessoa&id_produto=$idProduto&nu_qtd=$quantidade");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Mensagem'] != null && data['Mensagem'].toString().contains('sucesso');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removerItem(int idPessoa, int idProduto) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Excluir&id_pessoa=$idPessoa&id_produto=$idProduto");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Mensagem'] != null && data['Mensagem'].toString().contains('sucesso');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<CarrinhoItem>> listarItens(int idPessoa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=ListarPorPessoa&id_pessoa=$idPessoa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null && data['dados'] is List) {
          return (data['dados'] as List)
              .map((item) => CarrinhoItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> limparCarrinho(int idPessoa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=LimparCarrinho&id_pessoa=$idPessoa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Mensagem'] != null && data['Mensagem'].toString().contains('sucesso');
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

