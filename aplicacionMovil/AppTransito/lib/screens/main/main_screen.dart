import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/menu_button.dart';
import 'map_screen.dart';
import 'info_screen.dart';
import 'admin_screen.dart';
import 'vehicles_screen.dart';
import 'infracciones_screen.dart';
import '../auth/auth_screen.dart';
import '../../services/api_service_auth.dart';
import '../../second_app/screens/second_app_screen.dart';

class MainScreen extends StatefulWidget {
  final String role;
  final String token;
  final int userProfileId;

  const MainScreen({
    super.key,
    required this.role,
    required this.token,
    required this.userProfileId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isMenuOpen = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    _screens = [
      MapScreen(
        role: widget.role,
        token: widget.token,
      ), // Índice 0
      InfoScreen(
        title: 'Código de Tránsito', 
        message: AppConstants.codigoTransito,
      ), // Índice 1
      const InfoScreen(
        title: 'Horarios', 
        message: AppConstants.horarios,
      ), // Índice 2
      InfoScreen(
        title: 'Ayuda', 
        message: AppConstants.contactoAyuda,
      ), // Índice 3
      VehiclesScreen(
        token: widget.token,
        role: widget.role,
        userProfileId: widget.userProfileId,
      ), // Índice 4
      if (widget.role == Roles.policia) ...[
        const AdminScreen(), // Índice 5 para policía
        const SecondAppScreen(), // Índice 6 para policía
        InfraccionesScreen(
          token: widget.token,
        ), // Índice 7 para policía
      ],
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido ${widget.role == Roles.ciudadano ? 'Ciudadano' : 'Policía'}'),
          backgroundColor: roleColors[widget.role],
        ),
      );
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _changeScreen(int index) {
    setState(() {
      _currentIndex = index;
      _isMenuOpen = false;
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Mapa';
      case 1:
        return 'Código de Tránsito';
      case 2:
        return 'Horarios';
      case 3:
        return 'Ayuda';
      case 4:
        return 'Autos';
      case 5:
        return widget.role == Roles.policia ? 'Panel de Administración' : '';
      case 6:
        return widget.role == Roles.policia ? 'Notificaciones API' : '';
      case 7:
        return widget.role == Roles.policia ? 'Infracciones' : '';
      default:
        return 'App de Tránsito Inteligente';
    }
  }

  Color _getAppBarColor() {
    return widget.role == Roles.ciudadano 
        ? Colors.blue
        : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _getAppBarColor(),
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: _toggleMenu,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (_isMenuOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Material(
                        color: _currentIndex == 0 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _changeScreen(0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.map,
                                  color: _currentIndex == 0 ? Colors.blue : Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    'Mapa',
                                    style: TextStyle(
                                      color: _currentIndex == 0 ? Colors.blue : Colors.grey[700],
                                      fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Material(
                        color: _currentIndex == 1 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _changeScreen(1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: _currentIndex == 1 ? Colors.blue : Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    'Información',
                                    style: TextStyle(
                                      color: _currentIndex == 1 ? Colors.blue : Colors.grey[700],
                                      fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Material(
                        color: _currentIndex == 2 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _changeScreen(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: _currentIndex == 2 ? Colors.blue : Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    'Horarios',
                                    style: TextStyle(
                                      color: _currentIndex == 2 ? Colors.blue : Colors.grey[700],
                                      fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Material(
                        color: _currentIndex == 3 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _changeScreen(3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.help,
                                  color: _currentIndex == 3 ? Colors.blue : Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    'Ayuda',
                                    style: TextStyle(
                                      color: _currentIndex == 3 ? Colors.blue : Colors.grey[700],
                                      fontWeight: _currentIndex == 3 ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Material(
                        color: _currentIndex == 4 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _changeScreen(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: _currentIndex == 4 ? Colors.blue : Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    'Autos',
                                    style: TextStyle(
                                      color: _currentIndex == 4 ? Colors.blue : Colors.grey[700],
                                      fontWeight: _currentIndex == 4 ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.role == Roles.policia) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Material(
                          color: _currentIndex == 5 ? Colors.green.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            onTap: () => _changeScreen(5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    color: _currentIndex == 5 ? Colors.green : Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: _currentIndex == 5 ? Colors.green : Colors.grey[700],
                                        fontWeight: _currentIndex == 5 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Material(
                          color: _currentIndex == 6 ? Colors.green.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            onTap: () => _changeScreen(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    color: _currentIndex == 6 ? Colors.green : Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Text(
                                      'Notificaciones',
                                      style: TextStyle(
                                        color: _currentIndex == 6 ? Colors.green : Colors.grey[700],
                                        fontWeight: _currentIndex == 6 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Material(
                          color: _currentIndex == 7 ? Colors.green.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            onTap: () => _changeScreen(7),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: _currentIndex == 7 ? Colors.green : Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Text(
                                      'Infracciones',
                                      style: TextStyle(
                                        color: _currentIndex == 7 ? Colors.green : Colors.grey[700],
                                        fontWeight: _currentIndex == 7 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar Sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await ApiServiceAuth().logout();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al cerrar sesión: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}