import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../tema.dart';
import 'tela_aula.dart';
import 'tela_trilhas.dart';

// ============================================================
// DASHBOARD DO ALUNO (RF03 e RF13)
// Mostra, de cima para baixo: saudação, botão para continuar a próxima aula,
// nível, números grandes, últimas explicações, gráfico de XP e progresso por trilha.
// Todos os dados vêm de uma única chamada: GET /dashboard.
// ============================================================
const _corFogo = Color(0xFFFF9F5A);

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
          final notaMedia = d['nota_media'] as int?;
          final proximaAula = d['proxima_aula'] as Map<String, dynamic>?;
          final ultimas = (d['ultimas_producoes'] as List<dynamic>?) ?? const [];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    primeiroNome.isEmpty ? 'Olá!' : 'Olá, $primeiroNome!',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Veja como está o seu progresso.',
                    style: TextStyle(color: CoresAprendo.textoSuave),
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
                  _GradeNumeros(
                    numeros: [
                      _NumeroGrande(
                        valor: '$diasSeguidos',
                        rotulo: diasSeguidos == 1 ? 'Dia seguido' : 'Dias seguidos',
                        icone: Icons.local_fire_department,
                        cor: _corFogo,
                      ),
                      _NumeroGrande(
                        valor: '${d['xp_total']}',
                        rotulo: 'XP total',
                        icone: Icons.bolt,
                        cor: CoresAprendo.ouro,
                      ),
                      _NumeroGrande(
                        valor: '${d['aulas_concluidas']}/${d['total_aulas']}',
                        rotulo: 'Aulas concluídas',
                        icone: Icons.check_circle,
                        cor: CoresAprendo.turquesa,
                      ),
                      _NumeroGrande(
                        valor: notaMedia == null ? '-' : '$notaMedia',
                        rotulo: 'Nota média',
                        icone: Icons.grade,
                        cor: CoresAprendo.texto,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Secao(
                    titulo: 'Últimas explicações',
                    child: _UltimasExplicacoes(
                      producoes: ultimas,
                      enviadas: (d['producoes_enviadas'] as int?) ?? 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Secao(
                    titulo: 'XP nos últimos 7 dias',
                    child: _GraficoXp(dias: d['xp_ultimos_7_dias'] as List<dynamic>),
                  ),
                  const SizedBox(height: 16),
                  _Secao(
                    titulo: 'Progresso por trilha',
                    child: _ProgressoTrilhas(trilhas: d['trilhas'] as List<dynamic>),
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
class _GradeNumeros extends StatelessWidget {
  final List<Widget> numeros;

  const _GradeNumeros({required this.numeros});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        const espaco = 12.0;
        final colunas = limites.maxWidth >= 640 ? 4 : 2;
        final largura =
            ((limites.maxWidth - espaco * (colunas - 1)) / colunas).floorToDouble();
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final numero in numeros) SizedBox(width: largura, child: numero),
          ],
        );
      },
    );
  }
}

// Cor, ícone e nome de cada resultado da correção
(Color, IconData, String) _aparenciaDoResultado(dynamic resultado) => switch (resultado) {
      'suficiente' => (CoresAprendo.turquesa, Icons.check_circle, 'Suficiente'),
      'parcial' => (CoresAprendo.ouro, Icons.lightbulb, 'Parcial'),
      _ => (CoresAprendo.erro, Icons.refresh, 'Insuficiente'),
    };

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
    final (cor, icone, rotulo) = _aparenciaDoResultado(producao['resultado']);
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

class _NumeroGrande extends StatelessWidget {
  final String valor;
  final String rotulo;
  final IconData icone;
  final Color cor;

  const _NumeroGrande({
    required this.valor,
    required this.rotulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: cor),
              ),
            ),
            const SizedBox(height: 4),
            Text(rotulo, style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Secao({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// Gráfico de barras do XP ganho em cada um dos últimos 7 dias
class _GraficoXp extends StatelessWidget {
  final List<dynamic> dias;

  const _GraficoXp({required this.dias});

  static const _nomesDias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  static const _alturaMaxima = 140.0;

  String _rotulo(String data, bool ehHoje) {
    if (ehHoje) return 'hoje';
    return _nomesDias[DateTime.parse(data).weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final valores = dias.map((dia) => dia['xp'] as int).toList();
    final maximo = valores.fold<int>(0, (a, b) => b > a ? b : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _alturaMaxima + 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < dias.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        valores[i] > 0 ? '${valores[i]}' : '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CoresAprendo.ouro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: maximo == 0
                            ? 4
                            : (valores[i] / maximo * _alturaMaxima).clamp(4.0, _alturaMaxima),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: valores[i] > 0 ? CoresAprendo.ouro : CoresAprendo.superficieClara,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rotulo(dias[i]['dia'] as String, i == dias.length - 1),
                        style: const TextStyle(fontSize: 12, color: CoresAprendo.textoSuave),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (maximo == 0) ...[
          const SizedBox(height: 12),
          const Text(
            'Conclua uma aula para ganhar o seu primeiro XP.',
            style: TextStyle(color: CoresAprendo.textoSuave),
          ),
        ],
      ],
    );
  }
}

class _ProgressoTrilhas extends StatelessWidget {
  final List<dynamic> trilhas;

  const _ProgressoTrilhas({required this.trilhas});

  @override
  Widget build(BuildContext context) {
    if (trilhas.isEmpty) {
      return const Text('Nenhuma trilha disponível.', style: TextStyle(color: CoresAprendo.textoSuave));
    }
    return Column(
      children: [
        for (final t in trilhas)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${t['nome']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${t['aulas_concluidas']}/${t['total_aulas']} aulas · ${t['percentual']}%',
                      style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (t['percentual'] as int) / 100,
                    minHeight: 10,
                    backgroundColor: CoresAprendo.superficieClara,
                    color: CoresAprendo.turquesa,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}