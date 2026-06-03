class Pessoa {
  final int idPessoa;
  final String nmPessoa;
  final String nuCpf;
  final String nuCel;
  final String dsEmail;
  final String nuCep;
  final String? dsComplemento;
  final int? nuEndereco;

  Pessoa({
    required this.idPessoa,
    required this.nmPessoa,
    required this.nuCpf,
    required this.nuCel,
    required this.dsEmail,
    required this.nuCep,
    this.dsComplemento,
    this.nuEndereco,
  });

  factory Pessoa.fromJson(Map<String, dynamic> json) {
    return Pessoa(
      idPessoa: int.parse(json['id_pessoa'].toString()),
      nmPessoa: json['nm_pessoa'] ?? '',
      nuCpf: json['nu_cpf'] ?? '',
      nuCel: json['nu_cel'] ?? '',
      dsEmail: json['ds_email'] ?? '',
      nuCep: json['nu_cep'] ?? '',
      dsComplemento: json['ds_complemento'],
      nuEndereco: json['nu_endereco'] != null ? int.parse(json['nu_endereco'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pessoa': idPessoa,
      'nm_pessoa': nmPessoa,
      'nu_cpf': nuCpf,
      'nu_cel': nuCel,
      'ds_email': dsEmail,
      'nu_cep': nuCep,
      'ds_complemento': dsComplemento,
      'nu_endereco': nuEndereco,
    };
  }

  String get enderecoFormatado {
    String endereco = '';
    if (dsComplemento != null && dsComplemento!.isNotEmpty) {
      endereco = dsComplemento!;
    }
    if (nuEndereco != null) {
      if (endereco.isNotEmpty) {
        endereco += ', $nuEndereco';
      } else {
        endereco = nuEndereco.toString();
      }
    }
    return endereco.isEmpty ? 'Endereço não cadastrado' : endereco;
  }
}

