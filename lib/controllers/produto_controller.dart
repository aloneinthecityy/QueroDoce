import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto.dart';

class ProdutoController {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudProduto.php";

  static Future<List<Produto>> listarProdutosRecentes() async {
    try {
      final url = Uri.parse("$baseUrl?oper=ListarProdutosRecentes");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print('DEBUG - Resposta do servidor: ${response.body}');
        // print('DEBUG - Dados decodificados: $data');
        
        if (data['dados'] != null) {
          // Debug: verificar URLs de imagens
          if (data['dados'] is List) {
            for (var item in data['dados']) {
              if (item['nm_imagem'] != null) {
                print('DEBUG - nm_imagem do produto ${item['id_produto']}: ${item['nm_imagem']}');
              }
            }
          }
          // O backend pode retornar como array ou objeto único
          if (data['dados'] is List) {
            return (data['dados'] as List)
                .map((item) {
                  try {
                    return Produto.fromJson(item);
                  } catch (e) {
                    print('Erro ao converter produto: $e - Item: $item');
                    return null;
                  }
                })
                .whereType<Produto>()
                .toList();
          } else if (data['dados'] is Map) {
            // Se retornar um único objeto, converter para lista
            return [Produto.fromJson(data['dados'])];
          }
        }
        print('DEBUG - Nenhum dado encontrado na resposta');
      } else {
        print('DEBUG - Status code: ${response.statusCode}');
        print('DEBUG - Resposta: ${response.body}');
      }
      return [];
    } catch (e) {
      print('DEBUG - Erro na requisição: $e');
      return [];
    }
  }

  static Future<List<Produto>> listarProdutosPorCategoria(int idCategoria) async {
    try {
      final url = Uri.parse("$baseUrl?oper=ListarProdutosPorCategoria&id_categoria=$idCategoria");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null && data['dados'] is List) {
          return (data['dados'] as List)
              .map((item) => Produto.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Produto?> buscarProduto(int idProduto) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Consultar&id_produto=$idProduto");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null) {
          if (data['dados'] is List && (data['dados'] as List).isNotEmpty) {
            return Produto.fromJson(data['dados'][0]);
          } else if (data['dados'] is Map) {
            return Produto.fromJson(data['dados']);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

