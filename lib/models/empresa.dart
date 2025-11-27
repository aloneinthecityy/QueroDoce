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
      return Empresa(
        idEmpresa: json['id_empresa'] != null
            ? int.parse(json['id_empresa'].toString())
            : 0,
        nmEmpresa: json['nm_empresa']?.toString() ?? '',
        dsEmail: json['ds_email']?.toString() ?? '',
        nmImagem: json['nm_imagem']?.toString() ?? '',
        dsSenha: json['ds_senha']?.toString() ?? '',
        nuCnpj: json['nu_cnpj']?.toString() ?? '',
        nuCep: json['nu_cep']?.toString() ?? '',
        dsComplemento: json['ds_complemento']?.toString() ?? '',
        nuEndereco: json['nu_endereco'] != null
            ? int.parse(json['nu_endereco'].toString())
            : 0,
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
}
