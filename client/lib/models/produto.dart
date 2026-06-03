class Produto {
  final int idProduto;
  final int idEmpresa;
  final String nmProduto;
  final String dsProduto;
  final String nmImagem;
  final double vlProduto;
  final int nuQtd;
  final bool flDisponivel;
  final String? nmEmpresa;

  Produto({
    required this.idProduto,
    required this.idEmpresa,
    required this.nmProduto,
    required this.dsProduto,
    required this.nmImagem,
    required this.vlProduto,
    required this.nuQtd,
    required this.flDisponivel,
    this.nmEmpresa,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    try {
      return Produto(
        idProduto: json['id_produto'] != null ? int.parse(json['id_produto'].toString()) : 0,
        idEmpresa: json['id_empresa'] != null ? int.parse(json['id_empresa'].toString()) : 0,
        nmProduto: json['nm_produto']?.toString() ?? '',
        dsProduto: json['ds_produto']?.toString() ?? '',
        nmImagem: json['nm_imagem']?.toString() ?? '',
        vlProduto: json['vl_produto'] != null ? double.parse(json['vl_produto'].toString()) : 0.0,
        nuQtd: json['nu_qtd'] != null ? int.parse(json['nu_qtd'].toString()) : 0,
        flDisponivel: json['fl_disponivel'] == true || 
                      json['fl_disponivel'] == 'true' || 
                      json['fl_disponivel'] == 1 ||
                      json['fl_disponivel'] == 't',
        nmEmpresa: json['nm_empresa']?.toString(),
      );
    } catch (e) {
      print('Erro ao criar Produto do JSON: $e');
      print('JSON recebido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produto': idProduto,
      'id_empresa': idEmpresa,
      'nm_produto': nmProduto,
      'ds_produto': dsProduto,
      'nm_imagem': nmImagem,
      'vl_produto': vlProduto,
      'nu_qtd': nuQtd,
      'fl_disponivel': flDisponivel,
      'nm_empresa': nmEmpresa,
    };
  }
}

