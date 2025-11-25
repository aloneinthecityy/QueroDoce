class CarrinhoItem {
  final int idPessoa;
  final int idProduto;
  final int idEmpresa;
  int nuQtd;
  final String? nmProduto;
  final String? dsProduto;
  final double? vlProduto;
  final String? nmImagem;
  final String? nmEmpresa;

  CarrinhoItem({
    required this.idPessoa,
    required this.idProduto,
    required this.nuQtd,
    required this.idEmpresa,
    this.nmProduto,
    this.dsProduto,
    this.vlProduto,
    this.nmImagem,
    this.nmEmpresa,
  });

  factory CarrinhoItem.fromJson(Map<String, dynamic> json) {
    return CarrinhoItem(
      idPessoa: int.parse(json['id_pessoa'].toString()),
      idProduto: int.parse(json['id_produto'].toString()),
      nuQtd: int.parse(json['nu_qtd'].toString()),
      nmProduto: json['nm_produto'],
      dsProduto: json['ds_produto'],
      vlProduto: json['vl_produto'] != null ? double.parse(json['vl_produto'].toString()) : null,
      nmImagem: json['nm_imagem'],
      idEmpresa: int.parse(json['id_empresa'].toString()), 
      nmEmpresa: json['nm_empresa'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pessoa': idPessoa,
      'id_produto': idProduto,
      'nu_qtd': nuQtd,
      'id_empresa': idEmpresa,
    };
  }

  double get totalItem => (vlProduto ?? 0) * nuQtd;
}

