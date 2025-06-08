import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Panel de Administración',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  _buildAdminButton('Registrar Infracción', Icons.add_circle),
                  const SizedBox(height: 15),
                  _buildAdminButton('Ver Reportes', Icons.list_alt),
                  const SizedBox(height: 15),
                  _buildAdminButton('Gestión de Usuarios', Icons.people),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.green[50],
          foregroundColor: Colors.green[800],
        ),
        onPressed: () {
          // Aquí iría la lógica para cada función de admin
        },
      ),
    );
  }
}