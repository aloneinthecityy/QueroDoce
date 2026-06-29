class Empresa {
  final int idEmpresa;
  final String nmEmpresa;
  final String dsEmail;
  final String nmImagem;
  final String dsSenha;
  final String nuCnpj;
  final String nuCep;
  final String dsComplemento;
  final int nuEndereco;
  final int idCategoria;
  final String nmCategoria;
  final List<int> idsCategoria;
  final List<String> nomesCategoria;

  Empresa({
    required this.idEmpresa,
    required this.nmEmpresa,
    required this.dsEmail,
    required this.nmImagem,
    required this.dsSenha,
    required this.nuCnpj,
    required this.nuCep,
    required this.dsComplemento,
    required this.nuEndereco,
    required this.idCategoria,
    this.nmCategoria = '',
    List<int>? idsCategoria,
    List<String>? nomesCategoria,
  })  : idsCategoria =
            idsCategoria ?? (idCategoria > 0 ? <int>[idCategoria] : <int>[]),
        nomesCategoria = nomesCategoria ??
            (nmCategoria.trim().isNotEmpty ? <String>[nmCategoria] : <String>[]);

  factory Empresa.fromJson(Map<String, dynamic> json) {
    try {
      final idEmpresa = _readInt(json, const [
        'id_empresa',
        'idEmpresa',
        'empresa_id',
        'id',
        'ID_EMPRESA',
        'ID',
      ]);

      if (idEmpresa <= 0) {
        throw FormatException('ID da empresa invalido: $json');
      }

      final idsCategoria = _readIntList(json, const [
        'id_categorias',
        'idsCategoria',
        'ids_categoria',
        'categorias_ids',
      ]);
      final idCategoria = idsCategoria.isNotEmpty
          ? idsCategoria.first
          : _readInt(json, const [
              'id_categoria',
              'idCategoria',
              'categoria_id',
            ]);
      final nomesCategoria = _readStringList(json, const [
        'nm_categorias',
        'nomesCategoria',
        'nomes_categoria',
        'categorias',
      ]);
      final nmCategoria = nomesCategoria.isNotEmpty
          ? nomesCategoria.join(', ')
          : _readString(json, const [
              'nm_categoria',
              'nmCategoria',
              'categoria',
            ]);

      return Empresa(
        idEmpresa: idEmpresa,
        nmEmpresa: _readString(json, const ['nm_empresa', 'nmEmpresa', 'nome']),
        dsEmail: _readString(json, const ['ds_email', 'email']),
        nmImagem: _readString(json, const ['nm_imagem', 'nmImagem', 'imagem']),
        dsSenha: _readString(json, const ['ds_senha', 'senha']),
        nuCnpj: _readString(json, const ['nu_cnpj', 'cnpj']),
        nuCep: _readString(json, const ['nu_cep', 'cep']),
        dsComplemento: _readString(json, const [
          'ds_complemento',
          'complemento',
        ]),
        nuEndereco: _readInt(json, const ['nu_endereco', 'nuEndereco']),
        idCategoria: idCategoria,
        nmCategoria: nmCategoria,
        idsCategoria: idsCategoria.isNotEmpty
            ? idsCategoria
            : (idCategoria > 0 ? <int>[idCategoria] : <int>[]),
        nomesCategoria: nomesCategoria.isNotEmpty
            ? nomesCategoria
            : (nmCategoria.trim().isNotEmpty ? <String>[nmCategoria] : <String>[]),
      );
    } catch (e) {
      print('Erro ao criar Empresa do JSON: $e');
      print('JSON recebido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empresa': idEmpresa,
      'nm_empresa': nmEmpresa,
      'ds_email': dsEmail,
      'nm_imagem': nmImagem,
      'ds_senha': dsSenha,
      'nu_cnpj': nuCnpj,
      'nu_cep': nuCep,
      'ds_complemento': dsComplemento,
      'nu_endereco': nuEndereco,
      'id_categoria': idsCategoria.isNotEmpty ? idsCategoria.first : idCategoria,
      'id_categorias': idsCategoria.isNotEmpty
          ? idsCategoria.join(',')
          : (idCategoria > 0 ? idCategoria.toString() : ''),
    };
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }

    return '';
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is int) return value;
      if (value is num) return value.toInt();

      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }

    return 0;
  }

  static List<int> _readIntList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      final parsed = _parseIntList(value);
      if (parsed.isNotEmpty) return parsed;
    }

    return const [];
  }

  static List<int> _parseIntList(dynamic value) {
    if (value == null) return const [];

    final ids = <int>[];
    void addId(dynamic item) {
      int? parsed;
      if (item is Map) {
        parsed = _readInt(Map<String, dynamic>.from(item), const [
          'id_categoria',
          'idCategoria',
          'categoria_id',
          'id',
        ]);
      } else if (item is int) {
        parsed = item;
      } else if (item is num) {
        parsed = item.toInt();
      } else {
        parsed = int.tryParse(item.toString().trim());
      }

      if (parsed != null && parsed > 0 && !ids.contains(parsed)) {
        ids.add(parsed);
      }
    }

    if (value is List) {
      for (final item in value) {
        addId(item);
      }
      return ids;
    }

    for (final item in value.toString().split(RegExp(r'[,;|]'))) {
      addId(item);
    }

    return ids;
  }

  static List<String> _readStringList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      final parsed = _parseStringList(value);
      if (parsed.isNotEmpty) return parsed;
    }

    return const [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map((item) {
            if (item is Map) {
              return _readString(Map<String, dynamic>.from(item), const [
                'nm_categoria',
                'nmCategoria',
                'categoria',
                'nome',
              ]);
            }
            return item.toString();
          })
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return value
        .toString()
        .split(RegExp(r'[,;|]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
