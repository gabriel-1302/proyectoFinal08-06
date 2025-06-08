class ApiConstants {
  // Zonas restringidas
  static const String zonasBaseUrl         = 'http://192.168.1.9:8000/api';
  static const String zonasRestrigidasUrl  = '$zonasBaseUrl/zonas-restringidas/';

  // Autenticación (login) en otro servidor o ruta
  static const String authBaseUrl          = 'http://192.168.1.9:8080/api';  
  static const String loginUrl             = '$authBaseUrl/login/';

  // (Opcional) otros endpoints de auth
  // static const String refreshTokenUrl   = '$authBaseUrl/auth/refresh/';
  // static const String logoutUrl         = '$authBaseUrl/auth/logout/';
  
  // Nota:
  // - En emulador Android usa 10.0.2.2 en lugar de 192.168.1.10/1.20
  // - En iOS localhost, o la IP de tu máquina en dispositivos físicos
}

class AppConstants {
  // Textos informativos
  static const String codigoTransito = '''TITULO VI
DE LAS FALTAS Y SANCIONES
CAPITULO I
DE LAS INFRACCIONES Y SANCIONES

Artículo 380.- (Infracciones de primer grado). Las siguientes infracciones son de primer grado y serán sancionadas con:

1) Por la falta de asistencia a las víctimas en caso de accidente, con inhabilitación del brevet o licencia hasta que se conozca el fallo ejecutoriado de la justicia ordinaria sobre la responsabilidad y pena impuesta al conductor de acuerdo al artículo 262 del código penal.

2) Por la agresión o faltamiento grave a la autoridad de tránsito o peatones por parte de los conductores, auxiliares, usuarios o peatones, con cinco días de arresto, sin perjuicio de la sanción que corresponda imponer a los tribunales ordinarios de justicia.''';

  static const String horarios = 'Horario de atención:\nLunes a Viernes: 8:00 - 18:00\nSábados: 9:00 - 12:00';
  
  static const String contactoAyuda = '''Centro de Ayuda y Soporte

Para reportar infracciones de tránsito:
Teléfono: 800-123-4567
Email: transito@ciudad.com''';
}

class Roles {
  static const String ciudadano = 'ciudadano';
  static const String policia = 'policia';
}