import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/empresa.dart';

class EmpresaController {
  static const String baseUrl =
      "http://localhost:8000/Controller/CrudEmpresa.php";
  static String? ultimoErroLogin;

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
    ultimoErroLogin = null;

    try {
      final url = Uri.parse("$baseUrl?oper=Login");
      final response = await http.post(
        url,
        body: {'oper': 'Login', 'ds_email': email, 'ds_senha': senha},
      );

      if (response.statusCode != 200) {
        ultimoErroLogin =
            'Nao foi possivel entrar na conta da empresa agora. Tente novamente em instantes.';
        return null;
      }

      final responseBody = response.body.trim();
      if (responseBody.isEmpty) {
        ultimoErroLogin =
            'Recebemos uma resposta inesperada ao entrar na conta da empresa. Tente novamente.';
        return null;
      }

      final data = json.decode(responseBody);
      final mensagem = _readMensagem(data);
      final empresaData = _extractEmpresaData(data);

      if (empresaData == null) {
        ultimoErroLogin = _friendlyLoginMessage(mensagem);
        return null;
      }

      return Empresa.fromJson(empresaData);
    } on FormatException catch (e) {
      final mensagem = _readMensagemFromException(e);
      ultimoErroLogin = _friendlyLoginMessage(mensagem);
      return null;
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('Failed to fetch')) {
        ultimoErroLogin =
            'Nao foi possivel conectar ao sistema da empresa agora. Verifique sua conexao e tente novamente.';
      } else {
        ultimoErroLogin =
            'Nao foi possivel entrar na conta da empresa agora. Tente novamente em instantes.';
      }
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
      final url = Uri.parse("$baseUrl?oper=Alterar");
      final response = await http.post(
        url,
        body: empresa.toJson().map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['NumMens'] == 1 || data['mensagem'] == 1;
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

  static Map<String, dynamic>? _extractEmpresaData(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return _asMap(data.first);
    }

    if (data is! Map) return null;

    final numMens = data['NumMens'] ?? data['numMens'] ?? data['mensagem'];
    if (numMens == 0 || numMens == '0') return null;

    final dados = data['dados'] ?? data['Dados'] ?? data['DADOS'];

    if (dados is List && dados.isNotEmpty) {
      return _asMap(dados.first);
    }

    if (dados is Map) {
      return _asMap(dados);
    }

    return _asMap(data);
  }

  static String? _readMensagem(dynamic data) {
    if (data is! Map) return null;

    final value =
        data['mensagem'] ??
        data['Mensagem'] ??
        data['MENSAGEM'] ??
        data['message'] ??
        data['erro'] ??
        data['Erro'];

    if (value == null) return null;
    if (value == 1 || value == '1') return null;
    return value.toString();
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static String _friendlyLoginMessage(String? mensagem) {
    final texto = (mensagem ?? '').toLowerCase();

    if (texto.contains('e-mail') &&
        (texto.contains('nao encontrado') || texto.contains('não encontrado'))) {
      return 'Nao encontramos uma conta de empresa com esse e-mail. Confira o endereco digitado e tente novamente.';
    }

    if (texto.contains('senha')) {
      return 'O e-mail ou a senha da empresa nao conferem. Tente novamente.';
    }

    if (mensagem != null && mensagem.trim().isNotEmpty) {
      return mensagem;
    }

    return 'Nao foi possivel entrar na conta da empresa agora. Tente novamente em instantes.';
  }

  static String? _readMensagemFromException(FormatException exception) {
    final text = exception.message;
    if (text.contains('E-mail não encontrado')) {
      return 'E-mail não encontrado';
    }
    if (text.contains('E-mail nao encontrado')) {
      return 'E-mail nao encontrado';
    }
    if (text.contains('Senha inválida')) {
      return 'Senha inválida';
    }
    if (text.contains('Senha invalida')) {
      return 'Senha invalida';
    }
    return null;
  }
}
