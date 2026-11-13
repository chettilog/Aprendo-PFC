import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

// ============================================================
// TELA DE TERMOS DE USO
// ============================================================
class TelaTermos extends StatefulWidget {
  const TelaTermos({super.key});

  @override
  State<TelaTermos> createState() => _TelaTermosState();
}

class _TelaTermosState extends State<TelaTermos> {
  String _conteudo = '';
  String _versao = '';
  bool _carregando = true;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregarTermos();
  }

  Future<void> _carregarTermos() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/termos'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _conteudo = data['conteudo'];
          _versao = data['versao'];
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = data['error'] ?? 'Erro ao carregar termos';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro de conexão: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Termos de Uso ${_versao.isNotEmpty ? "(v$_versao)" : ""}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro.isNotEmpty
              ? Center(child: Text('Erro: $_erro', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _conteudo,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
    );
  }
}
// ============================================================
// TELA DE POLÍTICA DE PRIVACIDADE
// ============================================================
class TelaPolitica extends StatefulWidget {
  const TelaPolitica({super.key});

  @override
  State<TelaPolitica> createState() => _TelaPoliticaState();
}

class _TelaPoliticaState extends State<TelaPolitica> {
  String _conteudo = '';
  String _versao = '';
  bool _carregando = true;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregarPolitica();
  }

  Future<void> _carregarPolitica() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/politica'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _conteudo = data['conteudo'];
          _versao = data['versao'];
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = data['error'] ?? 'Erro ao carregar política';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro de conexão: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Política de Privacidade ${_versao.isNotEmpty ? "(v$_versao)" : ""}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro.isNotEmpty
              ? Center(child: Text('Erro: $_erro', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _conteudo,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
    );
  }
}
