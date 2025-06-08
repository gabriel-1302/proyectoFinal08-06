import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiServiceAuth {
  static final ApiServiceAuth _instance = ApiServiceAuth._internal();
  factory ApiServiceAuth() => _instance;
  ApiServiceAuth._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _loginUrl = ApiConstants.loginUrl;

  Future<Map<String, dynamic>> authenticate(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Estado de la respuesta: ${response.statusCode}'); // Depuración
      print('Cuerpo de la respuesta: ${response.body}'); // Depuración

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Respuesta de la API decodificada: $data'); // Depuración

        if (data.containsKey('token')) {
          await _storage.write(key: 'token', value: data['token']);
          print('Token guardado: ${data['token']}');
        }

        if (data.containsKey('role')) {
          await _storage.write(key: 'role', value: data['role']);
          print('Role guardado: ${data['role']}');
        }

        if (data.containsKey('user') && data['user'].containsKey('id')) {
          await _storage.write(key: 'userProfileId', value: data['user']['id'].toString());
          print('userProfileId guardado: ${data['user']['id']}');
        }

        return {
          'success': true,
          'token': data['token'],
          'role': data['role'],
          'user': data['user'],
          'message': data['message'] ?? 'Inicio de sesión exitoso',
        };
      } else {
        String errorMsg = 'Error al autenticar: ${response.statusCode}';
        try {
          final Map<String, dynamic> err = json.decode(response.body);
          errorMsg = err['message'] ?? errorMsg;
        } catch (_) {}
        print('Error en la API: $errorMsg'); // Depuración
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('Excepción en authenticate: $e'); // Depuración
      return {
        'success': false,
        'message': 'Excepción al autenticar: $e',
      };
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  Future<int?> getUserProfileId() async {
    final id = await _storage.read(key: 'userProfileId');
    return id != null ? int.tryParse(id) : null;
  }
}