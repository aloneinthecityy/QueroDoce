class BannerModel {
  final int idBanner;
  final String dtBanner;
  final String nmImagem;

  BannerModel({
    required this.idBanner,
    required this.dtBanner,
    required this.nmImagem,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      idBanner: int.parse(json['id_banner'].toString()),
      dtBanner: json['dt_banner'] ?? '',
      nmImagem: json['nm_imagem'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_banner': idBanner,
      'dt_banner': dtBanner,
      'nm_imagem': nmImagem,
    };
  }
}

