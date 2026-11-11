import 'package:flutter/material.dart';

class Colores {
  static const verde = Color(0xFF1B7F4B);
  static const verdeClaro = Color(0xFFE3F3EA);
  static const ambar = Color(0xFFF2A900);
  static const ambarClaro = Color(0xFFFFF4D6);
  static const ambarTexto = Color(0xFF8A6100);
  static const rojo = Color(0xFFD64545);
  static const rojoClaro = Color(0xFFFDEAEA);
  static const fondo = Color(0xFFF6F7F4);
  static const texto = Color(0xFF1A1F1C);
  static const gris = Color(0xFF6B746E);
}

ThemeData temaCaporal() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colores.verde, primary: Colores.verde),
      scaffoldBackgroundColor: Colores.fondo,
      appBarTheme: const AppBarTheme(backgroundColor: Colores.fondo, foregroundColor: Colores.texto, elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
