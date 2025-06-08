class ZonaRestringida {
  final int id;
  final double coordenada1_lat;
  final double coordenada1_lon;
  final double coordenada2_lat;
  final double coordenada2_lon;

  ZonaRestringida({
    required this.id,
    required this.coordenada1_lat,
    required this.coordenada1_lon,
    required this.coordenada2_lat,
    required this.coordenada2_lon,
  });

  factory ZonaRestringida.fromJson(Map<String, dynamic> json) {
    return ZonaRestringida(
      id: json['id'],
      coordenada1_lat: json['coordenada1_lat'].toDouble(),
      coordenada1_lon: json['coordenada1_lon'].toDouble(),
      coordenada2_lat: json['coordenada2_lat'].toDouble(),
      coordenada2_lon: json['coordenada2_lon'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coordenada1_lat': coordenada1_lat,
      'coordenada1_lon': coordenada1_lon,
      'coordenada2_lat': coordenada2_lat,
      'coordenada2_lon': coordenada2_lon,
    };
  }
}