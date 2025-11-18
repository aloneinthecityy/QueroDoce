import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categoria.dart';

class CategoriaController {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudCategoria.php";

  static Future<List<Categoria>> listarCategorias() async {
    try {
      final url = Uri.parse("$baseUrl?oper=Listar");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null && data['dados'] is List) {
          return (data['dados'] as List)
              .map((item) => Categoria.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

