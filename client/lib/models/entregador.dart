class Entregador {
  final int idEntregador;
  final String nmEntregador;
  final String dsEmail;
  final String nuCel;
  final String nuCpf;
  final String nuCep;
  final int nuEndereco;
  final String dsComplemento;
  final String tpLocomocao;
  final String nuCnh;

  Entregador({
    required this.idEntregador,
    required this.nmEntregador,
    required this.dsEmail,
    required this.nuCel,
    this.nuCpf = '',
    this.nuCep = '',
    this.nuEndereco = 0,
    this.dsComplemento = '',
    this.tpLocomocao = '',
    this.nuCnh = '',
  });

  factory Entregador.fromJson(Map<String, dynamic> json) {
    final idEntregador = _readInt(json, const [
      'id_entregador',
      'id_pessoa',
      'idEntregador',
      'idPessoa',
      'entregador_id',
      'pessoa_id',
      'id',
      'ID_ENTREGADOR',
      'ID_PESSOA',
      'ID',
      'cd_entregador',
      'cod_entregador',
    ]);

    if (idEntregador <= 0) {
      throw FormatException('ID do entregador invalido: $json');
    }

    return Entregador(
      idEntregador: idEntregador,
      nmEntregador:
          (json['nm_entregador'] ??
                  json['nmEntregador'] ??
                  json['nm_pessoa'] ??
                  json['nome'] ??
                  '')
              .toString(),
      dsEmail: (json['ds_email'] ?? json['email'] ?? '').toString(),
      nuCel: (json['nu_cel'] ?? json['telefone'] ?? '').toString(),
      nuCpf: (json['nu_cpf'] ?? json['cpf'] ?? '').toString(),
      nuCep: (json['nu_cep'] ?? json['cep'] ?? '').toString(),
      nuEndereco: _readInt(json, const ['nu_endereco', 'nuEndereco']),
      dsComplemento:
          (json['ds_complemento'] ?? json['complemento'] ?? '').toString(),
      tpLocomocao: (json['tp_locomocao'] ?? json['tpLocomocao'] ?? '')
          .toString(),
      nuCnh: (json['nu_cnh'] ?? json['nuCnh'] ?? '').toString(),
    );
  }

  Entregador copyWith({
    int? idEntregador,
    String? nmEntregador,
    String? dsEmail,
    String? nuCel,
    String? nuCpf,
    String? nuCep,
    int? nuEndereco,
    String? dsComplemento,
    String? tpLocomocao,
    String? nuCnh,
  }) {
    return Entregador(
      idEntregador: idEntregador ?? this.idEntregador,
      nmEntregador: nmEntregador ?? this.nmEntregador,
      dsEmail: dsEmail ?? this.dsEmail,
      nuCel: nuCel ?? this.nuCel,
      nuCpf: nuCpf ?? this.nuCpf,
      nuCep: nuCep ?? this.nuCep,
      nuEndereco: nuEndereco ?? this.nuEndereco,
      dsComplemento: dsComplemento ?? this.dsComplemento,
      tpLocomocao: tpLocomocao ?? this.tpLocomocao,
      nuCnh: nuCnh ?? this.nuCnh,
    );
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
