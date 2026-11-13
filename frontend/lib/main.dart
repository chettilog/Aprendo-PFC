import 'package:flutter/material.dart';
import 'tema.dart';
import 'telas/tela_login.dart';

// Ponto de entrada do app. Cada tela fica em um arquivo da pasta telas/.
void main() {
  runApp(const AprendoApp());
}

class AprendoApp extends StatelessWidget {
  const AprendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprendo',
      theme: temaAprendo(),
      debugShowCheckedModeBanner: false,
      home: const TelaLogin(),
    );
  }
}
