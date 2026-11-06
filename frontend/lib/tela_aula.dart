import 'package:flutter/material.dart';
import 'api.dart';
import 'tela_trilhas.dart';
import 'tema.dart';

// Mesmos limites do back-end (PRODUCAO_MIN e PRODUCAO_MAX no server.js)
const _producaoMin = 40;
const _producaoMax = 3000;

String? validarProducao(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Escreva a sua explicação antes de enviar';
  if (texto.length < _producaoMin) {
    return 'Escreva pelo menos $_producaoMin caracteres (faltam ${_producaoMin - texto.length})';
  }
  if (texto.length > _producaoMax) return 'Use no máximo $_producaoMax caracteres';
  return null;
}

// ============================================================
// TELA DA AULA: conteúdo (RF05), produção (RF06), feedback (RF07) e XP (RF08)
// ============================================================
class TelaAula extends StatefulWidget {
  final int id;
  final bool concluida;

  const TelaAula({super.key, required this.id, required this.concluida});

  @override
  State<TelaAula> createState() => _TelaAulaState();
}

class _TelaAulaState extends State<TelaAula> {
  late Future<Map<String, dynamic>> _futuro;
  final _formKey = GlobalKey<FormState>();
  final _producaoController = TextEditingController();
  bool _enviando = false;
  String? _erroEnvio;
  Map<String, dynamic>? _resultado; // resposta do envio: feedback e XP

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  @override
  void dispose() {
    _producaoController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _carregar() async {
    final dados = await apiGet('/aulas/${widget.id}');
    return Map<String, dynamic>.from(dados['aula']);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erroEnvio = null;
    });
    try {
      final dados = await apiPost(
        '/aulas/${widget.id}/producoes',
        {'conteudo': _producaoController.text.trim()},
      );
      if (!mounted) return;
      setState(() => _resultado = Map<String, dynamic>.from(dados));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroEnvio = ehSessaoExpirada(e)
            ? 'Sua sessão expirou. Saia e entre novamente.'
            : mensagemDeErro(e);
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // Volta ao formulário mantendo o texto, para o aluno completar a explicação
  void _tentarDeNovo() => setState(() => _resultado = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aula')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          final aula = snap.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${aula['trilha_nome']}',
                    style: const TextStyle(
                      color: CoresAprendo.turquesa,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${aula['titulo']}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  if (widget.concluida) ...[
                    const SizedBox(height: 10),
                    const _Selo(
                      texto: 'Aula concluída',
                      cor: CoresAprendo.turquesa,
                      icone: Icons.check_circle,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '${aula['conteudo']}',
                        style: const TextStyle(fontSize: 17, height: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_resultado == null) _formulario() else _feedback(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Agora é a sua vez',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explique com as suas palavras o que você aprendeu nesta aula, '
            'como se estivesse ensinando um colega.',
            style: TextStyle(color: CoresAprendo.textoSuave),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _producaoController,
            validator: validarProducao,
            minLines: 5,
            maxLines: 12,
            maxLength: _producaoMax,
            decoration: const InputDecoration(
              hintText: 'Escreva aqui a sua explicação...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_erroEnvio != null) ...[
            const SizedBox(height: 8),
            Text(_erroEnvio!, style: const TextStyle(color: CoresAprendo.erro)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Enviar explicação'),
          ),
        ],
      ),
    );
  }

  Widget _feedback() {
    final feedback = _resultado!['feedback'];
    final xp = _resultado!['xp'];
    final suficiente = feedback['resultado'] == 'suficiente';
    final cor = suficiente ? CoresAprendo.turquesa : CoresAprendo.ouro;
    final ganho = xp['ganho'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        border: Border.all(color: cor, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(suficiente ? Icons.check_circle : Icons.lightbulb, color: cor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suficiente ? 'Mandou bem!' : 'Quase lá!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${feedback['comentario'] ?? ''}', style: const TextStyle(fontSize: 16)),
          if (suficiente) ...[
            const SizedBox(height: 16),
            Text(
              ganho > 0
                  ? '+$ganho XP  ·  Nível ${xp['nivel']}'
                  : 'Você já tinha ganhado o XP desta aula  ·  Nível ${xp['nivel']}',
              style: const TextStyle(
                color: CoresAprendo.ouro,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: suficiente ? () => Navigator.pop(context) : _tentarDeNovo,
            child: Text(suficiente ? 'Continuar' : 'Revisar e enviar de novo'),
          ),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  final String texto;
  final Color cor;
  final IconData icone;

  const _Selo({required this.texto, required this.cor, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 6),
            Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}