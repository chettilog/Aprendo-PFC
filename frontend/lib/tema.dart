import 'package:flutter/material.dart';

// Paleta do Aprendo (a mesma do protótipo no Figma)
class CoresAprendo {
  static const fundo = Color(0xFF14132B);
  static const superficie = Color(0xFF1E1D3F);
  static const superficieClara = Color(0xFF2A2952);
  static const texto = Color(0xFFF5F3FF);
  static const textoSuave = Color(0xFFB9B5D9);
  static const ouro = Color(0xFFF2B84B);
  static const turquesa = Color(0xFF3FD9C7);
  static const erro = Color(0xFFFF6B6B);
}

ThemeData temaAprendo() {
  const esquema = ColorScheme(
    brightness: Brightness.dark,
    primary: CoresAprendo.ouro,
    onPrimary: CoresAprendo.fundo,
    secondary: CoresAprendo.turquesa,
    onSecondary: CoresAprendo.fundo,
    error: CoresAprendo.erro,
    onError: CoresAprendo.fundo,
    surface: CoresAprendo.superficie,
    onSurface: CoresAprendo.texto,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: CoresAprendo.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: CoresAprendo.fundo,
      foregroundColor: CoresAprendo.texto,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: CoresAprendo.superficie,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoresAprendo.superficie,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}