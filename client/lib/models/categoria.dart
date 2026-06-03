class Categoria {
  final int idCategoria;
  final String nmCategoria;

  Categoria({
    required this.idCategoria,
    required this.nmCategoria,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: int.parse(json['id_categoria'].toString()),
      nmCategoria: json['nm_categoria'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nm_categoria': nmCategoria,
    };
  }
}

