import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/empresa.dart';

class EmpresaController {
  static const String baseUrl =
      "http://200.19.1.19/usuario01/Controller/CrudEmpresa.php";

  /// Lista todas as empresas
  static Future<List<Empresa>> listarEmpresas() async {
    try {
      final url = Uri.parse("$baseUrl?oper=Listar");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null && data['dados'] is List) {
          return (data['dados'] as List)
              .map((item) => Empresa.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao listar empresas: $e');
      return [];
    }
  }

  /// Busca uma empresa pelo ID
  static Future<Empresa?> buscarEmpresa(int idEmpresa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Consultar&id_empresa=$idEmpresa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null) {
          if (data['dados'] is Map) {
            return Empresa.fromJson(data['dados']);
          } else if (data['dados'] is List &&
              (data['dados'] as List).isNotEmpty) {
            return Empresa.fromJson(data['dados'][0]);
          }
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar empresa: $e');
      return null;
    }
  }

  /// Login da empresa
  static Future<Empresa?> login(String email, String senha) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Login");
      final response = await http.post(
        url,
        body: {'ds_email': email, 'ds_senha': senha},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null &&
            data['dados'] is List &&
            (data['dados'] as List).isNotEmpty) {
          return Empresa.fromJson(data['dados'][0]);
        } else if (data['dados'] != null && data['dados'] is Map) {
          return Empresa.fromJson(data['dados']);
        }
      }
      return null;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  /// Listar empresas por categoria
  static Future<List<Empresa>> listarPorCategoria(int idCategoria) async {
    try {
      final url = Uri.parse(
        "$baseUrl?oper=ListarPorCategoria&id_categoria=$idCategoria",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null && data['dados'] is List) {
          return (data['dados'] as List)
              .map((item) => Empresa.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao listar empresas por categoria: $e');
      return [];
    }
  }

  /// Inserir nova empresa
  static Future<bool> inserirEmpresa(Empresa empresa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Inserir");
      final response = await http.post(
        url,
        body: empresa.toJson().map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['mensagem'] == 1;
      }
      return false;
    } catch (e) {
      print('Erro ao inserir empresa: $e');
      return false;
    }
  }

  /// Alterar dados da empresa
  static Future<bool> alterarEmpresa(Empresa empresa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=AlterarDadosEmpresa");
      final response = await http.post(
        url,
        body: empresa.toJson().map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['mensagem'] == 1;
      }
      return false;
    } catch (e) {
      print('Erro ao alterar empresa: $e');
      return false;
    }
  }

  /// Excluir empresa
  static Future<bool> excluirEmpresa(int idEmpresa) async {
    try {
      final url = Uri.parse("$baseUrl?oper=Excluir&id_empresa=$idEmpresa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['mensagem'] == 1;
      }
      return false;
    } catch (e) {
      print('Erro ao excluir empresa: $e');
      return false;
    }
  }
}
