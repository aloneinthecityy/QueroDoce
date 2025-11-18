import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner.dart';

class BannerController {
  static const String baseUrl = "http://200.19.1.19/usuario01/Controller/CrudBanner.php";

  static Future<BannerModel?> buscarUltimoBanner() async {
    try {
      final url = Uri.parse("$baseUrl?oper=BuscarUltimoBanner");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dados'] != null) {
          if (data['dados'] is List && (data['dados'] as List).isNotEmpty) {
            return BannerModel.fromJson(data['dados'][0]);
          } else if (data['dados'] is Map) {
            return BannerModel.fromJson(data['dados']);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

