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
  });

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
}
