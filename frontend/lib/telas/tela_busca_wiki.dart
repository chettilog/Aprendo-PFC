import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

// ============================================================
// TELA DE BUSCA WIKIPEDIA (integração com API externa)
// ============================================================
class TelaBuscaWiki extends StatefulWidget {
  const TelaBuscaWiki({super.key});

  @override
  State<TelaBuscaWiki> createState() => _TelaBuscaWikiState();
}

class _TelaBuscaWikiState extends State<TelaBuscaWiki> {
  final _topicoController = TextEditingController();
  bool _carregando = false;
  Map<String, dynamic>? _resultado;
  String _erro = '';

  Future<void> _buscar() async {
    final topico = _topicoController.text.trim();
    if (topico.isEmpty) return;

    setState(() {
      _carregando = true;
      _erro = '';
      _resultado = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$apiBase/wiki/${Uri.encodeComponent(topico)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _resultado = data;
          _carregando = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _erro = 'Tópico não encontrado. Tente outro termo, com atenção aos acentos.';
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = data['error'] ?? 'Erro ao buscar tópico';
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
        title: const Text('Explorar conteúdo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pesquise um tópico',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conteúdo enciclopédico complementar às aulas, integrado à Wikipedia.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _topicoController,
                        decoration: const InputDecoration(
                          labelText: 'Tópico',
                          hintText: 'Ex: Fotossíntese, Brasil, Segunda Guerra Mundial',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _buscar(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _carregando ? null : _buscar,
                      child: _carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Buscar'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Mensagem de erro
                if (_erro.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _erro,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Resultado da busca
                if (_resultado != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_resultado!['imagem'] != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _resultado!['imagem'],
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, erro, pilha) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _resultado!['titulo'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_resultado!['descricao'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _resultado!['descricao'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            _resultado!['resumo'] ?? '',
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fonte: Wikipedia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
