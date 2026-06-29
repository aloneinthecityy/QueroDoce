import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/entregador.dart';

class EntregadorController {
  static const String baseUrl =
      'http://localhost:8000/Controller/CrudEntregador.php';

  static String? ultimoErroLogin;
  static String? ultimoErroCadastro;
  static String? ultimaMensagemCadastro;
  static String? ultimoErroAlteracao;

  static const Map<String, Map<String, String>> _mensagens = {
    'aceito': {
      'titulo': 'Pedido confirmado!',
      'mensagem': 'Um entregador aceitou seu pedido e esta indo para a loja!',
    },
    'coletando': {
      'titulo': 'Entregador na loja!',
      'mensagem': 'Seu entregador chegou a loja e esta retirando seus doces!',
    },
    'em_entrega': {
      'titulo': 'Pedido a caminho!',
      'mensagem': 'Seu pedido saiu para entrega! Toque para acompanhar no mapa.',
    },
    'entregue': {
      'titulo': 'Pedido entregue!',
      'mensagem': 'Bom apetite! Obrigado por escolher o QueroDoce.',
    },
  };

  static Future<Entregador?> login(String email, String senha) async {
    ultimoErroLogin = null;

    try {
      final url = Uri.parse('$baseUrl?oper=Login');
      final response = await http.post(
        url,
        body: {'oper': 'Login', 'ds_email': email, 'ds_senha': senha},
      );

      if (response.statusCode != 200) {
        ultimoErroLogin =
            'Nao foi possivel entrar na conta de entregador agora. Tente novamente em instantes.';
        return null;
      }

      final responseBody = response.body.trim();
      if (responseBody.isEmpty) {
        ultimoErroLogin =
            'Recebemos uma resposta inesperada ao entrar na conta de entregador. Tente novamente.';
        return null;
      }

      final data = json.decode(responseBody);
      final entregadorData = _extractEntregadorData(data);
      if (entregadorData != null) {
        return Entregador.fromJson(entregadorData);
      }

      ultimoErroLogin = _friendlyLoginMessage(_readMensagem(data));
      return null;
    } catch (e) {
      ultimoErroLogin =
          'Nao foi possivel entrar na conta de entregador agora. Verifique sua conexao e tente novamente.';
      print('Erro no login do entregador: $e');
      return null;
    }
  }

  static Future<bool> cadastrarCompleto({
    required String nome,
    required String cpf,
    required String celular,
    required String email,
    required String senha,
    required String cep,
    required String complemento,
    required int numeroEndereco,
    required String locomocao,
    required String cnh,
  }) async {
    ultimoErroCadastro = null;
    ultimaMensagemCadastro = null;

    try {
      final url = Uri.parse('$baseUrl?oper=CadastrarCompleto');
      final response = await http.post(
        url,
        body: {
          'oper': 'CadastrarCompleto',
          'nm_pessoa': nome,
          'nu_cpf': cpf,
          'nu_cel': celular,
          'ds_email': email,
          'ds_senha': senha,
          'nu_cep': cep,
          'ds_complemento': complemento,
          'nu_endereco': numeroEndereco.toString(),
          'tp_locomocao': locomocao,
          'nu_cnh': cnh,
        },
      );

      if (response.statusCode != 200) {
        ultimoErroCadastro =
            'Nao foi possivel concluir o cadastro do entregador agora. Tente novamente em instantes.';
        return false;
      }

      final responseBody = response.body.trim();
      if (responseBody.isEmpty) {
        ultimoErroCadastro =
            'Recebemos uma resposta inesperada ao cadastrar o entregador. Tente novamente.';
        return false;
      }

      final data = json.decode(responseBody);
      final sucesso = _isSuccess(data);
      final mensagem = _readMensagem(data);

      if (!sucesso) {
        ultimoErroCadastro = _friendlyCadastroMessage(mensagem);
        return false;
      }

      ultimaMensagemCadastro =
          mensagem ?? 'Cadastro do entregador realizado com sucesso.';
      return true;
    } catch (e) {
      ultimoErroCadastro =
          'Nao foi possivel concluir o cadastro do entregador agora. Verifique sua conexao e tente novamente.';
      print('Erro ao cadastrar entregador: $e');
      return false;
    }
  }

  static Future<Entregador?> buscarEntregador(int idEntregador) async {
    try {
      final url = Uri.parse('$baseUrl?oper=Consultar&id_entregador=$idEntregador');
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final responseBody = response.body.trim();
      if (responseBody.isEmpty) return null;

      final data = json.decode(responseBody);
      final entregadorData = _extractEntregadorData(data);
      if (entregadorData == null) return null;

      return Entregador.fromJson(entregadorData);
    } catch (e) {
      print('Erro ao buscar entregador: $e');
      return null;
    }
  }

  static Future<bool> alterarEntregador({
    required int idEntregador,
    required String nome,
    required String cpf,
    required String celular,
    required String email,
    required String cep,
    required int numeroEndereco,
    required String locomocao,
    required String cnh,
    String senha = '',
    String complemento = '',
  }) async {
    ultimoErroAlteracao = null;

    try {
      final url = Uri.parse('$baseUrl?oper=Alterar');
      final response = await http.post(
        url,
        body: {
          'oper': 'Alterar',
          'id_entregador': idEntregador.toString(),
          'nm_pessoa': nome,
          'nu_cpf': cpf,
          'nu_cel': celular,
          'ds_email': email,
          'ds_senha': senha,
          'nu_cep': cep,
          'ds_complemento': complemento,
          'nu_endereco': numeroEndereco.toString(),
          'tp_locomocao': locomocao,
          'nu_cnh': cnh,
        },
      );

      if (response.statusCode != 200) {
        ultimoErroAlteracao =
            'Nao foi possivel salvar as configuracoes do entregador agora.';
        return false;
      }

      final responseBody = response.body.trim();
      if (responseBody.isEmpty) {
        ultimoErroAlteracao =
            'Recebemos uma resposta inesperada ao salvar as configuracoes.';
        return false;
      }

      final data = json.decode(responseBody);
      if (_isSuccess(data)) return true;

      ultimoErroAlteracao = _friendlyCadastroMessage(_readMensagem(data));
      return false;
    } catch (e) {
      ultimoErroAlteracao =
          'Nao foi possivel salvar as configuracoes do entregador agora. Verifique sua conexao e tente novamente.';
      print('Erro ao alterar entregador: $e');
      return false;
    }
  }

  static Future<void> notificarCliente({
    required String pedidoDocId,
    required String novoStatus,
    required FirebaseFirestore firestore,
  }) async {
    final msg = _mensagens[novoStatus];
    if (msg == null) return;

    try {
      final pedidoDoc = await firestore.collection('pedidos').doc(pedidoDocId).get();

      final idCliente = pedidoDoc.data()?['idCliente']?.toString();
      if (idCliente == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(idCliente)
          .get();

      final token = userDoc.data()?['fcmToken'];
      if (token == null) return;

      await http.post(
        Uri.parse('http://localhost:8000/Controller/EnviarNotificacao.php'),
        body: {
          'token': token,
          'titulo': msg['titulo']!,
          'mensagem': msg['mensagem']!,
          'pedidoId': pedidoDocId,
          'status': novoStatus,
        },
      );
    } catch (e) {
      debugPrint('Erro ao enviar notificacao: $e');
    }
  }

  static Map<String, dynamic>? _extractEntregadorData(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return _asMap(data.first);
    }

    if (data is! Map) return null;
    if (!_isSuccess(data)) return null;

    final dados = data['dados'] ?? data['Dados'] ?? data['DADOS'];

    if (dados is List && dados.isNotEmpty) {
      return _asMap(dados.first);
    }

    if (dados is Map) {
      return _asMap(dados);
    }

    return _asMap(data);
  }

  static bool _isSuccess(dynamic data) {
    if (data is! Map) return false;
    final value = data['NumMens'] ?? data['numMens'] ?? data['mensagem'];
    return value == 1 || value == '1';
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

    if (texto.contains('e-mail ou senha invalidos')) {
      return 'O e-mail ou a senha do entregador nao conferem. Tente novamente.';
    }

    if (texto.contains('ainda nao esta vinculada')) {
      return 'Essa conta ainda nao esta cadastrada como entregador.';
    }

    if (mensagem != null && mensagem.trim().isNotEmpty) {
      return mensagem;
    }

    return 'Nao foi possivel entrar na conta de entregador agora. Tente novamente em instantes.';
  }

  static String _friendlyCadastroMessage(String? mensagem) {
    final texto = (mensagem ?? '').toLowerCase();

    if (texto.contains('esse e-mail')) {
      return 'Ja existe um entregador cadastrado com esse e-mail. Use outro endereco ou tente entrar na conta.';
    }

    if (texto.contains('esse cpf')) {
      return 'Ja existe um cadastro com esse CPF. Confira os dados informados.';
    }

    if (texto.contains('cpf valido')) {
      return 'Confira o CPF informado e tente novamente.';
    }

    if (texto.contains('esse celular')) {
      return 'Ja existe um cadastro com esse celular. Confira os dados informados.';
    }

    if (texto.contains('essa cnh')) {
      return 'Ja existe um entregador cadastrado com essa CNH.';
    }

    if (mensagem != null && mensagem.trim().isNotEmpty) {
      return mensagem;
    }

    return 'Nao foi possivel concluir o cadastro do entregador agora. Tente novamente em instantes.';
  }
}
