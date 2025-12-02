import 'package:flutter/material.dart';

class AppColors {
  // Colores principales para las funcionalidades
  static const Color kilometers = Color(0xFF388E3C);     // Verde material
  static const Color refuel = Color(0xFF1976D2); // Azul material
  static const Color mechanic = Color(0xFFF57C00);   // Naranja material
  static const Color delete = Color(0xFFD32F2F);     // Rojo material
  
  // Colores adicionales que puedas necesitar
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF757575);
  
  // Gradientes opcionales
  static const LinearGradient kilometersGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
  );
  
  static const LinearGradient refuelGradient = LinearGradient(
    colors: [Color(0xFF388E3C), Color(0xFF81C784)],
  );
}