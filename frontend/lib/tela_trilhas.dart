import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'tema.dart';
import 'tela_aula.dart';

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
    final progresso = <int, int>{
      for (final t in respostas[1]['dashboard']['trilhas'])
        t['id'] as int: t['percentual'] as int,
    };
    for (final t in trilhas) {
      t['percentual'] = progresso[t['id']] ?? 0;
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
                child: Text(
                  trilha['materia'],
                  style: const TextStyle(
                    color: CoresAprendo.turquesa,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
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
                '${trilha['total_aulas']} aulas',
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

class _TelaTrilhaState extends State<TelaTrilha> {
  late Future<List<Map<String, dynamic>>> _futuro;

  // Posição horizontal de cada aula, formando um caminho em zigue-zague
  static const _deslocamentos = [0.0, -0.5, -0.7, -0.5, 0.0, 0.5, 0.7, 0.5];

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
          final aulas = snap.data!;
          // A aula atual é a primeira ainda não concluída; as seguintes ficam bloqueadas
          final indiceAtual = aulas.indexWhere((a) => a['concluida'] != true);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                itemCount: aulas.length,
                itemBuilder: (context, indice) {
                  final aula = aulas[indice];
                  final estado = aula['concluida'] == true
                      ? _EstadoAula.concluida
                      : (indice == indiceAtual ? _EstadoAula.atual : _EstadoAula.bloqueada);
                  return Align(
                    alignment: Alignment(_deslocamentos[indice % _deslocamentos.length], 0),
                    child: _NoAula(
                      aula: aula,
                      estado: estado,
                      aoTocar: estado == _EstadoAula.bloqueada ? null : () => _abrirAula(aula),
                    ),
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

class _NoAula extends StatelessWidget {
  final Map<String, dynamic> aula;
  final _EstadoAula estado;
  final VoidCallback? aoTocar;

  const _NoAula({required this.aula, required this.estado, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    final (cor, icone) = switch (estado) {
      _EstadoAula.concluida => (CoresAprendo.turquesa, Icons.check_rounded),
      _EstadoAula.atual => (CoresAprendo.ouro, Icons.play_arrow_rounded),
      _EstadoAula.bloqueada => (CoresAprendo.superficieClara, Icons.lock_rounded),
    };
    final bloqueada = estado == _EstadoAula.bloqueada;
    final tamanho = estado == _EstadoAula.atual ? 84.0 : 72.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
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
            width: 150,
            child: Text(
              aula['titulo'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: bloqueada ? CoresAprendo.textoSuave : CoresAprendo.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}