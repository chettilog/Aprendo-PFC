import 'package:flutter/material.dart';
import '../api.dart';
import '../tema.dart';
import 'tela_aula.dart';
import 'tela_login.dart';

// ============================================================
// ESTADO DE ERRO (reutilizado pelas telas novas)
// ============================================================
bool ehSessaoExpirada(Object erro) =>
    erro is ApiErro && (erro.status == 401 || erro.status == 403);

String mensagemDeErro(Object erro) =>
    erro is ApiErro ? erro.mensagem : 'Não foi possível conectar ao servidor.';

class EstadoErro extends StatelessWidget {
  final Object erro;
  final VoidCallback aoTentarDeNovo;

  const EstadoErro({super.key, required this.erro, required this.aoTentarDeNovo});

  @override
  Widget build(BuildContext context) {
    final expirou = ehSessaoExpirada(erro);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expirou ? Icons.lock_clock : Icons.cloud_off,
              size: 56,
              color: CoresAprendo.textoSuave,
            ),
            const SizedBox(height: 16),
            Text(
              expirou ? 'Sua sessão expirou. Entre novamente.' : mensagemDeErro(erro),
              textAlign: TextAlign.center,
              style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: expirou
                  ? () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const TelaLogin()),
                        (rota) => false,
                      )
                  : aoTentarDeNovo,
              child: Text(expirou ? 'Entrar' : 'Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

// Ícone de cada matéria (usado no cartão da trilha)
IconData iconeDaMateria(dynamic materia) => switch (materia) {
      'Matemática' => Icons.calculate_rounded,
      'História' => Icons.account_balance_rounded,
      'Geografia' => Icons.public_rounded,
      _ => Icons.menu_book_rounded,
    };

// ============================================================
// LISTA DE TRILHAS (RF04 e RF13)
// ============================================================
class TelaTrilhas extends StatefulWidget {
  const TelaTrilhas({super.key});

  @override
  State<TelaTrilhas> createState() => _TelaTrilhasState();
}

class _TelaTrilhasState extends State<TelaTrilhas> {
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  // Busca as trilhas e junta o percentual de progresso de cada uma
  Future<List<Map<String, dynamic>>> _carregar() async {
    final respostas = await Future.wait([apiGet('/trilhas'), apiGet('/dashboard')]);
    final trilhas = List<Map<String, dynamic>>.from(respostas[0]['trilhas']);
    final progresso = <int, dynamic>{
      for (final t in respostas[1]['dashboard']['trilhas']) t['id'] as int: t,
    };
    for (final t in trilhas) {
      final dadosDoAluno = progresso[t['id']];
      t['percentual'] = dadosDoAluno == null ? 0 : dadosDoAluno['percentual'];
      t['aulas_concluidas'] = dadosDoAluno == null ? 0 : dadosDoAluno['aulas_concluidas'];
    }
    return trilhas;
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trilhas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          final trilhas = snap.data!;
          if (trilhas.isEmpty) {
            return const Center(child: Text('Nenhuma trilha disponível no momento.'));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: trilhas.length,
                separatorBuilder: (context, indice) => const SizedBox(height: 16),
                itemBuilder: (context, indice) {
                  final trilha = trilhas[indice];
                  return _CardTrilha(
                    trilha: trilha,
                    aoAbrir: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TelaTrilha(id: trilha['id'], nome: trilha['nome']),
                        ),
                      );
                      _recarregar();
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardTrilha extends StatelessWidget {
  final Map<String, dynamic> trilha;
  final VoidCallback aoAbrir;

  const _CardTrilha({required this.trilha, required this.aoAbrir});

  @override
  Widget build(BuildContext context) {
    final percentual = trilha['percentual'] as int;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoAbrir,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CoresAprendo.turquesa.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconeDaMateria(trilha['materia']), size: 14, color: CoresAprendo.turquesa),
                    const SizedBox(width: 6),
                    Text(
                      '${trilha['materia']}',
                      style: const TextStyle(
                        color: CoresAprendo.turquesa,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                trilha['nome'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (trilha['descricao'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  trilha['descricao'],
                  style: const TextStyle(color: CoresAprendo.textoSuave),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentual / 100,
                        minHeight: 10,
                        backgroundColor: CoresAprendo.superficieClara,
                        color: CoresAprendo.ouro,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$percentual%', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${trilha['aulas_concluidas'] ?? 0} de ${trilha['total_aulas']} aulas concluídas',
                style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CAMINHO DE AULAS DE UMA TRILHA (RF05)
// ============================================================
class TelaTrilha extends StatefulWidget {
  final int id;
  final String nome;

  const TelaTrilha({super.key, required this.id, required this.nome});

  @override
  State<TelaTrilha> createState() => _TelaTrilhaState();
}

enum _EstadoAula { concluida, atual, bloqueada }

// Largura reservada para cada aula do caminho (bolinha + título embaixo)
const _larguraNo = 150.0;

class _TelaTrilhaState extends State<TelaTrilha> {
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final dados = await apiGet('/trilhas/${widget.id}/aulas');
    return List<Map<String, dynamic>>.from(dados['aulas']);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  // Abre a aula e, ao voltar, recarrega o caminho (a próxima aula pode ter sido liberada)
  Future<void> _abrirAula(Map<String, dynamic> aula) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaAula(id: aula['id'], concluida: aula['concluida'] == true),
      ),
    );
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nome)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          return _CaminhoAulas(aulas: snap.data!, aoAbrir: _abrirAula);
        },
      ),
    );
  }
}

// O caminho em zigue-zague: uma bolinha por aula, ligadas por pontinhos.
// Ao abrir, a tela rola sozinha até a aula atual.
class _CaminhoAulas extends StatefulWidget {
  final List<Map<String, dynamic>> aulas;
  final void Function(Map<String, dynamic> aula) aoAbrir;

  const _CaminhoAulas({required this.aulas, required this.aoAbrir});

  @override
  State<_CaminhoAulas> createState() => _CaminhoAulasState();
}

class _CaminhoAulasState extends State<_CaminhoAulas> {
  // Posição horizontal de cada aula (-1 = esquerda, 0 = centro, 1 = direita)
  static const _deslocamentos = [0.0, -0.5, -0.7, -0.5, 0.0, 0.5, 0.7, 0.5];

  // Marca a bolinha da aula atual, para a tela conseguir rolar até ela
  final GlobalKey _chaveAulaAtual = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Espera a tela ser desenhada pela primeira vez e então rola até a aula atual
    WidgetsBinding.instance.addPostFrameCallback((_) => _rolarAteAulaAtual());
  }

  void _rolarAteAulaAtual() {
    final contexto = _chaveAulaAtual.currentContext;
    if (contexto == null) return; // todas as aulas concluídas: não há aula atual
    Scrollable.ensureVisible(
      contexto,
      alignment: 0.35,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  double _posicao(int indice) => _deslocamentos[indice % _deslocamentos.length];

  @override
  Widget build(BuildContext context) {
    final aulas = widget.aulas;
    // A aula atual é a primeira ainda não concluída; as seguintes ficam bloqueadas
    final indiceAtual = aulas.indexWhere((a) => a['concluida'] != true);

    _EstadoAula estadoDe(int indice) {
      if (aulas[indice]['concluida'] == true) return _EstadoAula.concluida;
      return indice == indiceAtual ? _EstadoAula.atual : _EstadoAula.bloqueada;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            children: [
              for (var i = 0; i < aulas.length; i++) ...[
                if (i > 0)
                  _Conector(
                    de: _posicao(i - 1),
                    ate: _posicao(i),
                    liberado: aulas[i - 1]['concluida'] == true,
                  ),
                Align(
                  alignment: Alignment(_posicao(i), 0),
                  child: _NoAula(
                    key: i == indiceAtual ? _chaveAulaAtual : null,
                    aula: aulas[i],
                    estado: estadoDe(i),
                    aoTocar: estadoDe(i) == _EstadoAula.bloqueada
                        ? null
                        : () => widget.aoAbrir(aulas[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Três pontinhos ligando uma aula à seguinte.
// Ficam coloridos quando a aula anterior já foi concluída (caminho liberado).
class _Conector extends StatelessWidget {
  final double de;
  final double ate;
  final bool liberado;

  const _Conector({required this.de, required this.ate, required this.liberado});

  @override
  Widget build(BuildContext context) {
    final cor = liberado ? CoresAprendo.turquesa : CoresAprendo.superficieClara;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          for (final fracao in const [0.25, 0.5, 0.75])
            Align(
              alignment: Alignment(de + (ate - de) * fracao, 0),
              child: SizedBox(
                width: _larguraNo,
                height: 16,
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoAula extends StatelessWidget {
  final Map<String, dynamic> aula;
  final _EstadoAula estado;
  final VoidCallback? aoTocar;

  const _NoAula({super.key, required this.aula, required this.estado, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    // "parcial" = o aluno já acertou parte da explicação, mas ainda não concluiu a aula
    final parcial = aula['parcial'] == true;
    final nota = aula['melhor_nota'];
    final (cor, icone) = switch (estado) {
      _EstadoAula.concluida => (CoresAprendo.turquesa, Icons.check_rounded),
      _EstadoAula.atual => (
          CoresAprendo.ouro,
          parcial ? Icons.star_half_rounded : Icons.play_arrow_rounded,
        ),
      _EstadoAula.bloqueada => (CoresAprendo.superficieClara, Icons.lock_rounded),
    };
    final bloqueada = estado == _EstadoAula.bloqueada;
    final tamanho = estado == _EstadoAula.atual ? 84.0 : 72.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: bloqueada ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: aoTocar,
              child: Container(
                width: tamanho,
                height: tamanho,
                decoration: BoxDecoration(
                  color: cor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(cor, Colors.black, 0.45)!,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  icone,
                  size: 38,
                  color: bloqueada ? CoresAprendo.textoSuave : CoresAprendo.fundo,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: _larguraNo,
            child: Column(
              children: [
                Text(
                  '${aula['titulo']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: bloqueada ? CoresAprendo.textoSuave : CoresAprendo.texto,
                  ),
                ),
                // Melhor nota que o aluno já tirou nesta aula
                if (!bloqueada && nota != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    parcial ? 'Nota $nota · falta completar' : 'Nota $nota',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
