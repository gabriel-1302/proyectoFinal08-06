import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> _getAuthData() async {
    final token = await _storage.read(key: 'token');
    final role = await _storage.read(key: 'role');
    final userProfileId = await _storage.read(key: 'userProfileId');
    print('Datos recuperados - token: $token, role: $role, userProfileId: $userProfileId'); // Depuración

    if (token != null && role != null && userProfileId != null) {
      return {
        'token': token,
        'userProfileId': int.parse(userProfileId),
        'role': role,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Tránsito Inteligente',
      theme: appTheme,
      routes: appRoutes,
      home: FutureBuilder<Map<String, dynamic>?>(
        future: _getAuthData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return MainScreen(
              role: snapshot.data!['role'],
              token: snapshot.data!['token'],
              userProfileId: snapshot.data!['userProfileId'],
            );
          }
          return const AuthScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}