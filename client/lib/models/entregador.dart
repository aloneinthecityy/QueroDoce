class Entregador {
  final int idEntregador;
  final String nmEntregador;
  final String dsEmail;
  final String nuCel;

  Entregador({
    required this.idEntregador,
    required this.nmEntregador,
    required this.dsEmail,
    required this.nuCel,
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
          (json['nm_entregador'] ?? json['nmEntregador'] ?? json['nome'] ?? '')
              .toString(),
      dsEmail: (json['ds_email'] ?? json['email'] ?? '').toString(),
      nuCel: (json['nu_cel'] ?? json['telefone'] ?? '').toString(),
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
