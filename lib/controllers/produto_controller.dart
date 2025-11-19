import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto.dart';

class ProdutoController {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudProduto.php";

  static Future<List<Produto>> listarProdutosRecentes() async {
    try {
      final url = Uri.parse("$baseUrl?oper=ListarProdutosRecentes");
      final response = await http.get(url);

      print('DEBUG - URL: $url');
      print('DEBUG - Status code: ${response.statusCode}');
      print('DEBUG - Resposta completa: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          print('DEBUG - Resposta vazia do servidor');
          return [];
        }
        
        final data = json.decode(responseBody);
        print('DEBUG - Dados decodificados: $data');
        
        if (data['dados'] != null) {
          print('DEBUG - Tipo de dados: ${data['dados'].runtimeType}');
          print('DEBUG - Quantidade de itens: ${data['dados'] is List ? (data['dados'] as List).length : 'N/A'}');
          
          // O backend pode retornar como array ou objeto único
          if (data['dados'] is List) {
            final produtos = (data['dados'] as List)
                .map((item) {
                  try {
                    print('DEBUG - Convertendo item: $item');
                    return Produto.fromJson(item);
                  } catch (e) {
                    print('Erro ao converter produto: $e - Item: $item');
                    return null;
                  }
                })
                .whereType<Produto>()
                .toList();
            print('DEBUG - Produtos convertidos: ${produtos.length}');
            return produtos;
          } else if (data['dados'] is Map) {
            // Se retornar um único objeto, converter para lista
            return [Produto.fromJson(data['dados'])];
          }
        } else {
          print('DEBUG - Campo "dados" é null na resposta');
          print('DEBUG - Mensagem: ${data['Mensagem']}');
        }
      } else {
        print('DEBUG - Status code: ${response.statusCode}');
        print('DEBUG - Resposta: ${response.body}');
      }
      return [];
    } catch (e) {
      print('DEBUG - Erro na requisição: $e');
      print('DEBUG - Stack trace: ${StackTrace.current}');
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

  static Future<List<Produto>> pesquisarProdutos(String termo) async {
    try {
      // Busca produtos pelo nome ou descrição
      final url = Uri.parse("$baseUrl?oper=Listar");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null && data['dados'] is List) {
          final todosProdutos = (data['dados'] as List)
              .map((item) {
                try {
                  return Produto.fromJson(item);
                } catch (e) {
                  return null;
                }
              })
              .whereType<Produto>()
              .toList();

          // Filtra produtos que contenham o termo de busca
          final termoLower = termo.toLowerCase();
          return todosProdutos.where((produto) {
            return produto.nmProduto.toLowerCase().contains(termoLower) ||
                   produto.dsProduto.toLowerCase().contains(termoLower) ||
                   (produto.nmEmpresa != null && produto.nmEmpresa!.toLowerCase().contains(termoLower));
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

