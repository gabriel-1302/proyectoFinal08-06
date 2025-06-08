
import 'package:flutter/material.dart';

// Tema global de la aplicación
final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 15),
    ),
  ),
);

// Colores específicos por rol
final Map<String, Color> roleColors = {
  'ciudadano': Colors.blue,
  'policia': Colors.green,
};