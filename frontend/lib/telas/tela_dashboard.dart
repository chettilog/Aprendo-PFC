import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../api.dart';
import '../componentes/cartoes.dart';
import '../tema.dart';
import 'tela_trilhas.dart';

// ============================================================
// DASHBOARD DO ALUNO (RF03)
// Indicadores e gráficos do estudo do aluno, de cima para baixo:
//   1. Indicadores: XP, nível, aulas concluídas, taxa de acerto, nota média, dias seguidos
//   2. Evolução do XP nos últimos 30 dias (gráfico de linha)
//   3. XP ganho por dia na última semana (gráfico de barras)
//   4. Resultado das explicações (gráfico de rosca)
//   5. Média de cada critério da rubrica (pontos fortes)
//   6. Desempenho por matéria
//   7. Melhor nota em cada aula
// Todos os dados vêm de uma única chamada: GET /estatisticas.
// Os gráficos são desenhados pelo próprio app (CustomPainter), sem bibliotecas extras.
// ============================================================
const _corFogo = Color(0xFFFF9F5A);

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  late Future<Map<String, dynamic>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<Map<String, dynamic>> _carregar() async {
    final dados = await apiGet('/estatisticas');
    return Map<String, dynamic>.from(dados['estatisticas']);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          final e = snap.data!;
          final resumo = Map<String, dynamic>.from(e['resumo'] as Map);
          final resultados = Map<String, dynamic>.from(e['resultados'] as Map);
          final xpPorDia = List<Map<String, dynamic>>.from(
            (e['xp_por_dia'] as List).map((d) => Map<String, dynamic>.from(d as Map)),
          );
          final notasPorAula = List<Map<String, dynamic>>.from(
            (e['notas_por_aula'] as List).map((a) => Map<String, dynamic>.from(a as Map)),
          );
          final criterios = Map<String, dynamic>.from(e['criterios_medios'] as Map);
          final porMateria = List<Map<String, dynamic>>.from(
            (e['por_materia'] as List).map((m) => Map<String, dynamic>.from(m as Map)),
          );
          final notaMedia = resumo['nota_media'];
          final diasSeguidos = resumo['dias_seguidos'] as int;

          return RefreshIndicator(
            onRefresh: () async => _recarregar(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Seus números de estudo',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Acompanhe a sua evolução e veja em que pontos melhorar.',
                      style: TextStyle(color: CoresAprendo.textoSuave),
                    ),
                    const SizedBox(height: 20),
                    GradeNumeros(
                      colunasTelaLarga: 3,
                      numeros: [
                        NumeroGrande(
                          valor: '${resumo['xp_total']}',
                          rotulo: 'XP total',
                          icone: Icons.bolt,
                          cor: CoresAprendo.ouro,
                        ),
                        NumeroGrande(
                          valor: '${resumo['nivel']}',
                          rotulo: 'Nível · ${resumo['xp_no_nivel']}/${resumo['xp_por_nivel']} XP',
                          icone: Icons.military_tech,
                          cor: CoresAprendo.ouro,
                        ),
                        NumeroGrande(
                          valor: '${resumo['aulas_concluidas']}/${resumo['total_aulas']}',
                          rotulo: 'Aulas concluídas',
                          icone: Icons.check_circle,
                          cor: CoresAprendo.turquesa,
                        ),
                        NumeroGrande(
                          valor: '${resumo['taxa_acerto']}%',
                          rotulo: 'Explicações suficientes',
                          icone: Icons.track_changes,
                          cor: CoresAprendo.turquesa,
                        ),
                        NumeroGrande(
                          valor: notaMedia == null ? '-' : '$notaMedia',
                          rotulo: 'Nota média',
                          icone: Icons.grade,
                          cor: CoresAprendo.texto,
                        ),
                        NumeroGrande(
                          valor: '$diasSeguidos',
                          rotulo: diasSeguidos == 1 ? 'Dia seguido' : 'Dias seguidos',
                          icone: Icons.local_fire_department,
                          cor: _corFogo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Secao(
                      titulo: 'Evolução do XP',
                      subtitulo: 'XP acumulado nos últimos 30 dias',
                      child: _GraficoLinha(dias: xpPorDia),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, limites) {
                        final semana = Secao(
                          titulo: 'XP por dia',
                          subtitulo: 'Últimos 7 dias',
                          child: _GraficoBarras(
                            dias: xpPorDia.sublist(math.max(0, xpPorDia.length - 7)),
                          ),
                        );
                        final rosca = Secao(
                          titulo: 'Resultado das explicações',
                          subtitulo: '${resumo['producoes_enviadas']} enviadas no total',
                          child: _GraficoRosca(resultados: resultados),
                        );
                        // Em telas largas os dois gráficos ficam lado a lado
                        if (limites.maxWidth < 700) {
                          return Column(children: [semana, const SizedBox(height: 16), rosca]);
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: semana),
                              const SizedBox(width: 12),
                              Expanded(child: rosca),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Secao(
                      titulo: 'Pontos fortes',
                      subtitulo: 'Média de cada critério da rubrica de correção',
                      child: _CriteriosMedios(criterios: criterios),
                    ),
                    const SizedBox(height: 16),
                    Secao(
                      titulo: 'Desempenho por matéria',
                      child: _DesempenhoMaterias(materias: porMateria),
                    ),
                    const SizedBox(height: 16),
                    Secao(
                      titulo: 'Melhor nota em cada aula',
                      subtitulo: 'Turquesa: concluída · Dourado: parcial · Vermelho: abaixo de 40',
                      child: _NotasPorAula(aulas: notasPorAula),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// "2026-11-16" -> "16/11"
String _diaMes(String data) {
  final d = DateTime.tryParse(data);
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// ------------------------------------------------------------
// 2. Gráfico de linha: XP acumulado
// ------------------------------------------------------------
class _GraficoLinha extends StatelessWidget {
  final List<Map<String, dynamic>> dias;

  const _GraficoLinha({required this.dias});

  @override
  Widget build(BuildContext context) {
    final valores = dias.map((d) => d['acumulado'] as int).toList();
    final ganhoNoPeriodo = valores.isEmpty ? 0 : valores.last - (valores.first - (dias.first['xp'] as int));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(painter: _PintorLinha(valores)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(dias.isEmpty ? '' : _diaMes(dias.first['dia'] as String),
                style: const TextStyle(fontSize: 12, color: CoresAprendo.textoSuave)),
            const Spacer(),
            const Text('hoje', style: TextStyle(fontSize: 12, color: CoresAprendo.textoSuave)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ganhoNoPeriodo > 0
              ? '+$ganhoNoPeriodo XP nos últimos 30 dias'
              : 'Nenhum XP nos últimos 30 dias. Conclua uma aula para começar.',
          style: const TextStyle(color: CoresAprendo.ouro, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PintorLinha extends CustomPainter {
  final List<int> valores;

  _PintorLinha(this.valores);

  @override
  void paint(Canvas canvas, Size size) {
    const margemTopo = 20.0;
    final grade = Paint()
      ..color = CoresAprendo.superficieClara
      ..strokeWidth = 1;
    // Linhas de referência horizontais
    for (var i = 0; i <= 3; i++) {
      final y = margemTopo + (size.height - margemTopo) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }
    if (valores.length < 2) return;

    final maximo = math.max(1, valores.reduce(math.max));
    Offset ponto(int i) => Offset(
          size.width * i / (valores.length - 1),
          size.height - (size.height - margemTopo) * valores[i] / maximo,
        );

    final linha = Path()..moveTo(ponto(0).dx, ponto(0).dy);
    for (var i = 1; i < valores.length; i++) {
      linha.lineTo(ponto(i).dx, ponto(i).dy);
    }
    // Área preenchida embaixo da linha
    final area = Path.from(linha)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = CoresAprendo.ouro.withValues(alpha: 0.15));
    canvas.drawPath(
      linha,
      Paint()
        ..color = CoresAprendo.ouro
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Ponto final destacado, com o valor atual
    final ultimo = ponto(valores.length - 1);
    canvas.drawCircle(ultimo, 5, Paint()..color = CoresAprendo.ouro);
    final rotulo = TextPainter(
      text: TextSpan(
        text: '${valores.last} XP',
        style: const TextStyle(color: CoresAprendo.ouro, fontSize: 12, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    rotulo.paint(canvas, Offset(ultimo.dx - rotulo.width, math.max(0, ultimo.dy - 22)));
  }

  @override
  bool shouldRepaint(covariant _PintorLinha antigo) => antigo.valores != valores;
}

// ------------------------------------------------------------
// 3. Gráfico de barras: XP por dia
// ------------------------------------------------------------
class _GraficoBarras extends StatelessWidget {
  final List<Map<String, dynamic>> dias;

  const _GraficoBarras({required this.dias});

  static const _nomesDias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  static const _alturaMaxima = 120.0;

  String _rotulo(String data, bool ehHoje) {
    if (ehHoje) return 'hoje';
    final d = DateTime.tryParse(data);
    return d == null ? '' : _nomesDias[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final valores = dias.map((d) => d['xp'] as int).toList();
    final maximo = valores.fold<int>(0, (a, b) => b > a ? b : a);

    return SizedBox(
      height: _alturaMaxima + 44,
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CoresAprendo.ouro),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: maximo == 0 ? 4 : (valores[i] / maximo * _alturaMaxima).clamp(4.0, _alturaMaxima),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: valores[i] > 0 ? CoresAprendo.ouro : CoresAprendo.superficieClara,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
    );
  }
}

// ------------------------------------------------------------
// 4. Gráfico de rosca: resultado das explicações
// ------------------------------------------------------------
class _GraficoRosca extends StatelessWidget {
  final Map<String, dynamic> resultados;

  const _GraficoRosca({required this.resultados});

  @override
  Widget build(BuildContext context) {
    final fatias = [
      for (final chave in ['suficiente', 'parcial', 'insuficiente'])
        (chave, (resultados[chave] as int?) ?? 0),
    ];
    final total = fatias.fold<int>(0, (soma, f) => soma + f.$2);
    if (total == 0) {
      return const Text(
        'Você ainda não enviou nenhuma explicação.',
        style: TextStyle(color: CoresAprendo.textoSuave),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _PintorRosca([
              for (final (chave, valor) in fatias) (aparenciaDoResultado(chave).$1, valor),
            ]),
            child: Center(
              child: Text(
                '$total',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (chave, valor) in fatias)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: aparenciaDoResultado(chave).$1,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(aparenciaDoResultado(chave).$3)),
                      Text(
                        '$valor · ${(valor * 100 / total).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PintorRosca extends CustomPainter {
  final List<(Color, int)> fatias;

  _PintorRosca(this.fatias);

  @override
  void paint(Canvas canvas, Size size) {
    final total = fatias.fold<int>(0, (soma, f) => soma + f.$2);
    if (total == 0) return;
    const espessura = 18.0;
    final retangulo = Rect.fromLTWH(
      espessura / 2,
      espessura / 2,
      size.width - espessura,
      size.height - espessura,
    );
    var inicio = -math.pi / 2; // começa no topo
    for (final (cor, valor) in fatias) {
      if (valor == 0) continue;
      final angulo = 2 * math.pi * valor / total;
      canvas.drawArc(
        retangulo,
        inicio,
        angulo,
        false,
        Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessura,
      );
      inicio += angulo;
    }
  }

  @override
  bool shouldRepaint(covariant _PintorRosca antigo) => antigo.fatias != fatias;
}

// ------------------------------------------------------------
// Barra horizontal com rótulo e valor, usada nos blocos 5, 6 e 7
// ------------------------------------------------------------
class _BarraHorizontal extends StatelessWidget {
  final String rotulo;
  final String? detalhe;
  final String valorTexto;
  final double fracao;
  final Color cor;
  final IconData? icone;

  const _BarraHorizontal({
    required this.rotulo,
    this.detalhe,
    required this.valorTexto,
    required this.fracao,
    required this.cor,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, size: 18, color: cor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(rotulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(valorTexto, style: TextStyle(color: cor, fontWeight: FontWeight.w800)),
            ],
          ),
          if (detalhe != null) ...[
            const SizedBox(height: 2),
            Text(detalhe!, style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 12)),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fracao.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: CoresAprendo.superficieClara,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// 5. Média de cada critério da rubrica
// ------------------------------------------------------------
class _CriteriosMedios extends StatelessWidget {
  final Map<String, dynamic> criterios;

  const _CriteriosMedios({required this.criterios});

  static const _rubrica = [
    ('conceito', 'Conceito correto', 50, Icons.school),
    ('completude', 'Completude', 30, Icons.checklist),
    ('clareza', 'Clareza e palavras próprias', 20, Icons.forum),
  ];

  @override
  Widget build(BuildContext context) {
    final avaliadas = (criterios['avaliadas'] as int?) ?? 0;
    if (avaliadas == 0) {
      return const Text(
        'Aparece depois que uma explicação sua for corrigida pela inteligência artificial.',
        style: TextStyle(color: CoresAprendo.textoSuave),
      );
    }

    // O critério com menor aproveitamento é o ponto a melhorar
    var piorRotulo = '';
    var piorFracao = 2.0;
    final barras = <Widget>[];
    for (final (chave, rotulo, maximo, icone) in _rubrica) {
      final valor = (criterios[chave] as int?) ?? 0;
      final fracao = valor / maximo;
      if (fracao < piorFracao) {
        piorFracao = fracao;
        piorRotulo = rotulo;
      }
      barras.add(_BarraHorizontal(
        rotulo: rotulo,
        valorTexto: '$valor/$maximo',
        fracao: fracao,
        cor: fracao >= 0.7
            ? CoresAprendo.turquesa
            : fracao >= 0.4
                ? CoresAprendo.ouro
                : CoresAprendo.erro,
        icone: icone,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...barras,
        Text(
          'Ponto a melhorar: $piorRotulo.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          avaliadas == 1
              ? 'Com base em 1 explicação corrigida pela IA.'
              : 'Com base em $avaliadas explicações corrigidas pela IA.',
          style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 12),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// 6. Desempenho por matéria
// ------------------------------------------------------------
class _DesempenhoMaterias extends StatelessWidget {
  final List<Map<String, dynamic>> materias;

  const _DesempenhoMaterias({required this.materias});

  @override
  Widget build(BuildContext context) {
    if (materias.isEmpty) {
      return const Text('Nenhuma matéria disponível.', style: TextStyle(color: CoresAprendo.textoSuave));
    }
    return Column(
      children: [
        for (final m in materias)
          _BarraHorizontal(
            rotulo: '${m['materia']}',
            detalhe: '${m['aulas_concluidas']} de ${m['total_aulas']} aulas concluídas'
                ' · ${m['xp']} XP'
                ' · nota média ${m['nota_media'] ?? '-'}',
            valorTexto: '${m['percentual']}%',
            fracao: (m['percentual'] as int) / 100,
            cor: CoresAprendo.turquesa,
            icone: iconeDaMateria(m['materia']),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------
// 7. Melhor nota em cada aula, agrupada por trilha
// ------------------------------------------------------------
class _NotasPorAula extends StatelessWidget {
  final List<Map<String, dynamic>> aulas;

  const _NotasPorAula({required this.aulas});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    String? trilhaAtual;
    for (final aula in aulas) {
      if (aula['trilha_nome'] != trilhaAtual) {
        trilhaAtual = aula['trilha_nome'] as String;
        widgets.add(Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 8, bottom: 10),
          child: Text(
            '${aula['materia']} · $trilhaAtual',
            style: const TextStyle(color: CoresAprendo.textoSuave, fontWeight: FontWeight.w700),
          ),
        ));
      }
      final nota = aula['melhor_nota'] as int?;
      final tentativas = (aula['tentativas'] as int?) ?? 0;
      final concluida = aula['concluida'] == true;
      final cor = nota == null
          ? CoresAprendo.superficieClara
          : concluida
              ? CoresAprendo.turquesa
              : nota >= 40
                  ? CoresAprendo.ouro
                  : CoresAprendo.erro;
      widgets.add(_BarraHorizontal(
        rotulo: '${aula['titulo']}',
        detalhe: tentativas == 0
            ? 'Ainda não tentada'
            : tentativas == 1
                ? '1 tentativa · ${aula['xp']} XP'
                : '$tentativas tentativas · ${aula['xp']} XP',
        valorTexto: nota == null ? '-' : '$nota',
        fracao: (nota ?? 0) / 100,
        cor: nota == null ? CoresAprendo.textoSuave : cor,
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
