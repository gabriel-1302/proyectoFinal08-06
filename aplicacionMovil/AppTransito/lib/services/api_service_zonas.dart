import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/zona_restringida.dart';
import '../utils/constants.dart';

class ApiServiceZonas {
  // Singleton pattern
  static final ApiServiceZonas _instance = ApiServiceZonas._internal();
  factory ApiServiceZonas() => _instance;
  ApiServiceZonas._internal();

  // Método para obtener zonas restringidas
  Future<List<ZonaRestringida>> getZonasRestringidas() async {
    try {
      // api_service_zonas.dart
      final response = await http.get(Uri.parse(ApiConstants.zonasRestrigidasUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => ZonaRestringida.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener zonas restringidas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Excepción al obtener zonas restringidas: $e');
    }
  }
}
