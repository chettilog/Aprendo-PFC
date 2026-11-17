import 'package:flutter/material.dart';
import '../api.dart';
import '../componentes/cartoes.dart';
import '../tema.dart';
import 'tela_respostas.dart';
import 'tela_trilhas.dart';

// ============================================================
// ABA ADMIN (só aparece para contas com perfil admin)
// Dois botões no topo:
//   - Visão geral: números da plataforma, sem dados de nenhum aluno (GET /admin/visao-geral)
//   - Logs: os 100 registros de auditoria mais recentes, com filtro de falhas (GET /logs)
// A permissão é conferida no servidor: um aluno que chamar essas rotas recebe 403.
// ============================================================
class TelaAdmin extends StatefulWidget {
  const TelaAdmin({super.key});

  @override
  State<TelaAdmin> createState() => _TelaAdminState();
}

class _TelaAdminState extends State<TelaAdmin> {
  int _aba = 0; // 0 = Visão geral, 1 = Logs

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administração')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Visão geral'), icon: Icon(Icons.bar_chart)),
                    ButtonSegment(value: 1, label: Text('Logs'), icon: Icon(Icons.receipt_long)),
                  ],
                  selected: {_aba},
                  onSelectionChanged: (escolha) => setState(() => _aba = escolha.first),
                ),
              ),
            ),
          ),
          Expanded(child: _aba == 0 ? const _VisaoGeral() : const _Logs()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Visão geral
class _VisaoGeral extends StatefulWidget {
  const _VisaoGeral();

  @override
  State<_VisaoGeral> createState() => _VisaoGeralState();
}

class _VisaoGeralState extends State<_VisaoGeral> {
  late Future<Map<String, dynamic>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<Map<String, dynamic>> _carregar() async {
    final dados = await apiGet('/admin/visao-geral');
    return Map<String, dynamic>.from(dados['visao_geral'] as Map);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  // Chave que vem da API, nome mostrado e cor de cada forma de correção
  static const _avaliadores = [
    ('ia', 'IA (Gemini)', CoresAprendo.turquesa),
    ('regras', 'Palavras-chave (reserva)', CoresAprendo.ouro),
    ('filtro', 'Filtro local (texto sem sentido ou cópia)', CoresAprendo.erro),
  ];

  int _numero(Map<String, dynamic> mapa, String chave) => (mapa[chave] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
        }
        final v = snap.data!;
        final alunos = Map<String, dynamic>.from(v['alunos'] as Map);
        final producoes = Map<String, dynamic>.from(v['producoes'] as Map);
        final resultados = Map<String, dynamic>.from(v['resultados'] as Map);
        final avaliadores = Map<String, dynamic>.from(v['avaliadores'] as Map);
        final aulas = List<Map<String, dynamic>>.from(
          (v['aulas_mais_dificeis'] as List).map((a) => Map<String, dynamic>.from(a as Map)),
        );
        final notaMedia = producoes['nota_media'];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GradeNumeros(numeros: [
                  NumeroGrande(
                    valor: '${_numero(alunos, 'total')}',
                    rotulo: 'Alunos cadastrados (+${_numero(alunos, 'novos_7_dias')} na semana)',
                    icone: Icons.groups,
                    cor: CoresAprendo.turquesa,
                  ),
                  NumeroGrande(
                    valor: '${_numero(alunos, 'ativos_7_dias')}',
                    rotulo: 'Alunos ativos nos últimos 7 dias',
                    icone: Icons.local_fire_department,
                    cor: CoresAprendo.ouro,
                  ),
                  NumeroGrande(
                    valor: '${_numero(producoes, 'total')}',
                    rotulo: 'Explicações enviadas (${_numero(producoes, 'ultimos_7_dias')} na semana)',
                    icone: Icons.edit_note,
                    cor: CoresAprendo.turquesa,
                  ),
                  NumeroGrande(
                    valor: notaMedia == null ? '-' : '$notaMedia',
                    rotulo: 'Nota média das explicações',
                    icone: Icons.grade,
                    cor: CoresAprendo.ouro,
                  ),
                ]),
                const SizedBox(height: 16),
                Secao(
                  titulo: 'Resultados das correções',
                  child: Column(
                    children: [
                      for (final resultado in ['suficiente', 'parcial', 'insuficiente'])
                        _LinhaContagem(
                          rotulo: aparenciaDoResultado(resultado).$3,
                          cor: aparenciaDoResultado(resultado).$1,
                          valor: _numero(resultados, resultado),
                          total: resultados.values.fold<int>(0, (soma, n) => soma + (n as num).toInt()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Secao(
                  titulo: 'Quem corrigiu',
                  subtitulo: 'Mostra se a IA está respondendo ou se o sistema está usando a reserva',
                  child: Column(
                    children: [
                      for (final item in _avaliadores)
                        _LinhaContagem(
                          rotulo: item.$2,
                          cor: item.$3,
                          valor: _numero(avaliadores, item.$1),
                          total: avaliadores.values.fold<int>(0, (soma, n) => soma + (n as num).toInt()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Secao(
                  titulo: 'Aulas com mais dificuldade',
                  subtitulo: 'As 5 aulas com a menor nota média',
                  child: aulas.isEmpty
                      ? const Text(
                          'Ainda não há explicações enviadas.',
                          style: TextStyle(color: CoresAprendo.textoSuave),
                        )
                      : Column(
                          children: [
                            for (final aula in aulas)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('${aula['titulo']}'),
                                subtitle: Text(
                                  '${aula['trilha_nome']} · ${aula['tentativas']} tentativas · '
                                  '${aula['taxa_acerto']}% suficientes',
                                ),
                                trailing: Text(
                                  '${aula['nota_media']}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: CoresAprendo.ouro,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Linha com rótulo, barra proporcional e quantidade
class _LinhaContagem extends StatelessWidget {
  final String rotulo;
  final Color cor;
  final int valor;
  final int total;

  const _LinhaContagem({required this.rotulo, required this.cor, required this.valor, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(rotulo)),
              Text('$valor', style: TextStyle(color: cor, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : valor / total,
              minHeight: 8,
              color: cor,
              backgroundColor: CoresAprendo.superficieClara,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Logs
// Nome amigável de cada ação gravada nos logs
String nomeDaAcao(dynamic acao) => switch (acao) {
      'cadastro' => 'Cadastro',
      'cadastro_falha' => 'Cadastro recusado',
      'login' => 'Login',
      'login_falha' => 'Login recusado',
      'acesso_negado' => 'Acesso negado',
      'acesso_perfil' => 'Consulta ao perfil',
      'edicao_perfil' => 'Troca de nome',
      'edicao_avatar' => 'Troca de avatar',
      'troca_senha' => 'Troca de senha',
      'troca_senha_falha' => 'Troca de senha recusada',
      'exclusao_conta' => 'Exclusão de conta',
      'busca_wiki' => 'Busca na Wikipedia',
      'busca_wiki_sem_resultado' => 'Busca na Wikipedia sem resultado',
      'ranking_adicionar' => 'Colega adicionado ao ranking',
      'ranking_visibilidade' => 'Visibilidade no ranking',
      'consulta_logs' => 'Consulta aos logs (admin)',
      _ => '$acao',
    };

class _Logs extends StatefulWidget {
  const _Logs();

  @override
  State<_Logs> createState() => _LogsState();
}

class _LogsState extends State<_Logs> {
  bool _apenasFalhas = false;
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final dados = await apiGet(_apenasFalhas ? '/logs?falhas=true' : '/logs');
    return List<Map<String, dynamic>>.from(
      (dados['logs'] as List).map((l) => Map<String, dynamic>.from(l as Map)),
    );
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Só falhas'),
                    selected: _apenasFalhas,
                    onSelected: (marcado) {
                      _apenasFalhas = marcado;
                      _recarregar();
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Atualizar',
                    onPressed: _recarregar,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
                  }
                  final logs = snap.data!;
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('Nenhum registro.', style: TextStyle(color: CoresAprendo.textoSuave)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: logs.length + 1,
                    separatorBuilder: (context, indice) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i == logs.length) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Mostrando os 100 registros mais recentes. Os logs são apagados '
                            'automaticamente depois de 6 meses, e os e-mails aparecem mascarados.',
                            style: TextStyle(color: CoresAprendo.textoSuave, fontSize: 12),
                          ),
                        );
                      }
                      return _LinhaLog(log: logs[i]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaLog extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LinhaLog({required this.log});

  @override
  Widget build(BuildContext context) {
    final deuCerto = log['sucesso'] == true;
    final cor = deuCerto ? CoresAprendo.turquesa : CoresAprendo.erro;
    final usuario = log['usuario_nome'] ?? (log['usuario_id'] == null ? 'Sem conta' : 'Conta excluída');
    final detalhes = '${log['detalhes'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresAprendo.superficieClara,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(deuCerto ? Icons.check_circle : Icons.error, color: cor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomeDaAcao(log['acao']), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('$usuario · ${formatarDataHora(log['criado_em'])}',
                    style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13)),
                if (detalhes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(detalhes, style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
