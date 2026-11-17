import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../componentes/avatar.dart';
import '../componentes/cartoes.dart';
import '../tema.dart';
import 'tela_aula.dart';
import 'tela_trilhas.dart';

// ============================================================
// TELA INÍCIO (aba "Início")
// Ponto de partida do aluno: saudação, botão para continuar a próxima aula,
// nível e últimas explicações. Os indicadores e gráficos ficam na aba Dashboard
// (telas/tela_dashboard.dart).
// Dados: GET /dashboard.
// ============================================================

class TelaPainel extends StatefulWidget {
  const TelaPainel({super.key});

  @override
  State<TelaPainel> createState() => _TelaPainelState();
}

class _TelaPainelState extends State<TelaPainel> {
  late Future<Map<String, dynamic>> _futuro;
  String _nome = '';

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _nome = prefs.getString('nome_usuario') ?? '');
  }

  Future<Map<String, dynamic>> _carregar() async {
    final dados = await apiGet('/dashboard');
    return Map<String, dynamic>.from(dados['dashboard']);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  // Abre a próxima aula e, ao voltar, recarrega os números do dashboard
  Future<void> _abrirAula(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaAula(id: id, concluida: false)),
    );
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          final d = snap.data!;
          final nomeCompleto = (d['nome'] as String?) ?? _nome;
          final primeiroNome = nomeCompleto.trim().split(' ').first;
          final nivel = d['nivel'] as int;
          final xpNoNivel = d['xp_no_nivel'] as int;
          final xpPorNivel = d['xp_por_nivel'] as int;
          final diasSeguidos = (d['dias_seguidos'] as int?) ?? 0;
          final proximaAula = d['proxima_aula'] as Map<String, dynamic>?;
          final ultimas = (d['ultimas_producoes'] as List<dynamic>?) ?? const [];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      AvatarAprendo(indice: indiceDoAvatar(d['avatar']), tamanho: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primeiroNome.isEmpty ? 'Olá!' : 'Olá, $primeiroNome!',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Que bom te ver por aqui.',
                              style: TextStyle(color: CoresAprendo.textoSuave),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _CartaoContinuar(
                    aula: proximaAula,
                    aoContinuar: proximaAula == null
                        ? null
                        : () => _abrirAula(proximaAula['id'] as int),
                  ),
                  const SizedBox(height: 16),
                  _CartaoNivel(
                    nivel: nivel,
                    xpNoNivel: xpNoNivel,
                    xpPorNivel: xpPorNivel,
                    xpQueFalta: (d['xp_para_proximo_nivel'] as int?) ?? (xpPorNivel - xpNoNivel),
                  ),
                  const SizedBox(height: 16),
                  Secao(
                    titulo: 'Últimas explicações',
                    child: _UltimasExplicacoes(
                      producoes: ultimas,
                      enviadas: (d['producoes_enviadas'] as int?) ?? 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    diasSeguidos > 0
                        ? 'Você está há $diasSeguidos ${diasSeguidos == 1 ? 'dia' : 'dias'} seguidos estudando. '
                            'Veja todos os seus números na aba Dashboard.'
                        : 'Veja todos os seus números na aba Dashboard.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CoresAprendo.textoSuave),
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

class _CartaoNivel extends StatelessWidget {
  final int nivel;
  final int xpNoNivel;
  final int xpPorNivel;
  final int xpQueFalta;

  const _CartaoNivel({
    required this.nivel,
    required this.xpNoNivel,
    required this.xpPorNivel,
    required this.xpQueFalta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2F7A), CoresAprendo.superficie],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: CoresAprendo.ouro, shape: BoxShape.circle),
            child: Text(
              '$nivel',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: CoresAprendo.fundo,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível $nivel',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: xpPorNivel == 0 ? 0 : xpNoNivel / xpPorNivel,
                    minHeight: 12,
                    backgroundColor: CoresAprendo.superficieClara,
                    color: CoresAprendo.ouro,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Faltam $xpQueFalta XP para o nível ${nivel + 1}  ·  $xpNoNivel de $xpPorNivel',
                  style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão "Continue de onde parou": leva direto para a próxima aula não concluída
class _CartaoContinuar extends StatelessWidget {
  final Map<String, dynamic>? aula;
  final VoidCallback? aoContinuar;

  const _CartaoContinuar({required this.aula, required this.aoContinuar});

  @override
  Widget build(BuildContext context) {
    final aula = this.aula;
    if (aula == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: CoresAprendo.ouro, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Você concluiu todas as aulas disponíveis. Parabéns!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Continue de onde parou',
              style: TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '${aula['titulo']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Trilha: ${aula['trilha_nome']}',
              style: const TextStyle(color: CoresAprendo.textoSuave),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: aoContinuar,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuar de onde parei'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Organiza os números grandes: 4 por linha em telas largas, 2 por linha no celular
// Lista das 3 explicações mais recentes, com a nota de cada uma
class _UltimasExplicacoes extends StatelessWidget {
  final List<dynamic> producoes;
  final int enviadas;

  const _UltimasExplicacoes({required this.producoes, required this.enviadas});

  @override
  Widget build(BuildContext context) {
    if (producoes.isEmpty) {
      return const Text(
        'Você ainda não enviou nenhuma explicação.',
        style: TextStyle(color: CoresAprendo.textoSuave),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final producao in producoes)
          _LinhaExplicacao(producao: Map<String, dynamic>.from(producao as Map)),
        Text(
          enviadas == 1 ? '1 explicação enviada no total' : '$enviadas explicações enviadas no total',
          style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
        ),
      ],
    );
  }
}

class _LinhaExplicacao extends StatelessWidget {
  final Map<String, dynamic> producao;

  const _LinhaExplicacao({required this.producao});

  @override
  Widget build(BuildContext context) {
    final (cor, icone, rotulo) = aparenciaDoResultado(producao['resultado']);
    final nota = producao['nota'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${producao['aula_titulo']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(rotulo, style: TextStyle(color: cor, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            nota == null ? '-' : '$nota/100',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cor),
          ),
        ],
      ),
    );
  }
}
