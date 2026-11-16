import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../componentes/cartoes.dart';
import '../tema.dart';
import 'tela_trilhas.dart';

// ============================================================
// RANKING ENTRE COLEGAS
// Cada aluno tem um código no formato Nome#1234. Quem recebe o código de um colega
// pode adicioná-lo e comparar o XP. O ranking mostra só o primeiro nome, o nível e o XP,
// e o aluno pode deixar de aparecer no ranking dos outros a qualquer momento (LGPD).
// Dados: GET /ranking, POST e DELETE /ranking/colegas, PUT /ranking/visibilidade.
// ============================================================
class TelaRanking extends StatefulWidget {
  const TelaRanking({super.key});

  @override
  State<TelaRanking> createState() => _TelaRankingState();
}

class _TelaRankingState extends State<TelaRanking> {
  late Future<Map<String, dynamic>> _futuro;
  final _codigoController = TextEditingController();
  bool _adicionando = false;
  String? _erroAdicionar;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _carregar() async {
    final dados = await apiGet('/ranking');
    return Map<String, dynamic>.from(dados as Map);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (mounted) _avisar('Código copiado: $codigo');
  }

  Future<void> _adicionar() async {
    final codigo = _codigoController.text.trim();
    if (!RegExp(r'^[^#\s]+\s*#\s*\d{4}$').hasMatch(codigo)) {
      setState(() => _erroAdicionar = 'Digite o código no formato Nome#1234');
      return;
    }
    setState(() {
      _adicionando = true;
      _erroAdicionar = null;
    });
    try {
      final dados = await apiPost('/ranking/colegas', {'codigo': codigo});
      _codigoController.clear();
      if (mounted) {
        _avisar('${dados['colega']} foi adicionado ao seu ranking!');
        _recarregar();
      }
    } catch (e) {
      if (mounted) setState(() => _erroAdicionar = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _adicionando = false);
    }
  }

  Future<void> _remover(Map<String, dynamic> colega) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover colega'),
        content: Text('Remover ${colega['nome']} do seu ranking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmou != true) return;
    final numero = '${colega['codigo']}'.split('#').last;
    try {
      await apiDelete('/ranking/colegas/$numero');
      if (mounted) _recarregar();
    } catch (e) {
      if (mounted) _avisar(mensagemDeErro(e));
    }
  }

  Future<void> _alterarVisibilidade(bool aparecer) async {
    try {
      await apiPut('/ranking/visibilidade', {'aparecer': aparecer});
      if (mounted) {
        _avisar(aparecer
            ? 'Você voltou a aparecer no ranking dos colegas.'
            : 'Você não aparece mais no ranking dos colegas.');
        _recarregar();
      }
    } catch (e) {
      if (mounted) _avisar(mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          final dados = snap.data!;
          final meuCodigo = '${dados['meu_codigo']}';
          final aparecer = dados['aparecer_no_ranking'] == true;
          final ranking = List<Map<String, dynamic>>.from(
            (dados['ranking'] as List).map((p) => Map<String, dynamic>.from(p as Map)),
          );
          final semColegas = ranking.length <= 1;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ---------- Meu código ----------
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seu código', style: TextStyle(color: CoresAprendo.textoSuave)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  meuCodigo,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: CoresAprendo.ouro,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar código',
                                onPressed: () => _copiarCodigo(meuCodigo),
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                          const Text(
                            'Passe esse código para um colega te adicionar e vocês compararem o XP.',
                            style: TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ---------- Adicionar colega ----------
                  Secao(
                    titulo: 'Adicionar colega',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codigoController,
                            onSubmitted: (_) {
                              if (!_adicionando) _adicionar();
                            },
                            decoration: InputDecoration(
                              labelText: 'Código do colega',
                              hintText: 'Ex.: Maria#1234',
                              border: const OutlineInputBorder(),
                              errorText: _erroAdicionar,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: FilledButton(
                            onPressed: _adicionando ? null : _adicionar,
                            child: _adicionando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  )
                                : const Text('Adicionar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ---------- Ranking ----------
                  Secao(
                    titulo: 'Ranking entre colegas',
                    subtitulo: 'Ordenado pelo XP total',
                    child: Column(
                      children: [
                        for (final pessoa in ranking)
                          _LinhaRanking(
                            pessoa: pessoa,
                            aoRemover: pessoa['eu'] == true ? null : () => _remover(pessoa),
                          ),
                        if (semColegas)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Adicione colegas pelo código para começar a disputa!',
                              style: TextStyle(color: CoresAprendo.textoSuave),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ---------- Privacidade ----------
                  Card(
                    child: SwitchListTile(
                      value: aparecer,
                      onChanged: _alterarVisibilidade,
                      title: const Text('Aparecer no ranking dos colegas'),
                      subtitle: const Text(
                        'Os colegas que tiverem o seu código veem só o seu primeiro nome, '
                        'o seu nível e o seu XP. Desligue para não aparecer para ninguém.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LinhaRanking extends StatelessWidget {
  final Map<String, dynamic> pessoa;
  final VoidCallback? aoRemover;

  const _LinhaRanking({required this.pessoa, required this.aoRemover});

  // Ouro, prata e bronze para os três primeiros
  static const _medalhas = [Color(0xFFF2B84B), Color(0xFFC9CCD6), Color(0xFFCD8B5A)];

  @override
  Widget build(BuildContext context) {
    final posicao = pessoa['posicao'] as int;
    final eu = pessoa['eu'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: eu ? CoresAprendo.ouro.withValues(alpha: 0.12) : CoresAprendo.superficieClara,
        border: Border.all(color: eu ? CoresAprendo.ouro : Colors.transparent, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: posicao <= 3
                ? Icon(Icons.emoji_events, color: _medalhas[posicao - 1], size: 28)
                : Text(
                    '$posicaoº',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eu ? '${pessoa['nome']} (você)' : '${pessoa['nome']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Nível ${pessoa['nivel']}',
                  style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${pessoa['xp_total']} XP',
            style: const TextStyle(color: CoresAprendo.ouro, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (aoRemover != null)
            IconButton(
              tooltip: 'Remover do ranking',
              onPressed: aoRemover,
              icon: const Icon(Icons.close, size: 20, color: CoresAprendo.textoSuave),
            ),
        ],
      ),
    );
  }
}
