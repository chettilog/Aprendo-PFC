import 'package:flutter/material.dart';
import '../api.dart';
import '../componentes/cartoes.dart';
import '../tema.dart';
import 'tela_trilhas.dart';

// ============================================================
// RESPOSTAS ANTERIORES DE UMA AULA
// Lista as explicações que o aluno já enviou na aula, da mais recente para a mais antiga,
// com a data, a nota, o resultado e o comentário de cada uma.
// Dados: GET /aulas/:id/producoes (só as produções do próprio aluno).
// Ao tocar em "Reaproveitar este texto", a tela fecha e devolve o texto para a aula.
// ============================================================
class TelaRespostas extends StatefulWidget {
  final int aulaId;
  final String tituloAula;

  const TelaRespostas({super.key, required this.aulaId, required this.tituloAula});

  @override
  State<TelaRespostas> createState() => _TelaRespostasState();
}

// "2026-11-16T15:20:00.000Z" -> "16/11/2026 às 12:20" (no horário do aparelho)
String formatarDataHora(dynamic valor) {
  final data = DateTime.tryParse('${valor ?? ''}')?.toLocal();
  if (data == null) return '-';
  String dd(int n) => n.toString().padLeft(2, '0');
  return '${dd(data.day)}/${dd(data.month)}/${data.year} às ${dd(data.hour)}:${dd(data.minute)}';
}

class _TelaRespostasState extends State<TelaRespostas> {
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final dados = await apiGet('/aulas/${widget.aulaId}/producoes');
    return List<Map<String, dynamic>>.from(
      (dados['producoes'] as List).map((p) => Map<String, dynamic>.from(p as Map)),
    );
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas respostas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, aoTentarDeNovo: _recarregar);
          }
          final respostas = snap.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.tituloAula,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    respostas.isEmpty
                        ? 'Você ainda não enviou nenhuma explicação nesta aula.'
                        : respostas.length == 1
                            ? '1 explicação enviada'
                            : '${respostas.length} explicações enviadas, da mais recente para a mais antiga',
                    style: const TextStyle(color: CoresAprendo.textoSuave),
                  ),
                  const SizedBox(height: 16),
                  for (final resposta in respostas) _CartaoResposta(resposta: resposta),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartaoResposta extends StatelessWidget {
  final Map<String, dynamic> resposta;

  const _CartaoResposta({required this.resposta});

  @override
  Widget build(BuildContext context) {
    final (cor, icone, rotulo) = aparenciaDoResultado(resposta['resultado']);
    final nota = resposta['nota'];
    final criterios = resposta['criterios'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icone, color: cor),
                const SizedBox(width: 8),
                Text(rotulo, style: TextStyle(color: cor, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(
                  nota == null ? '-' : '$nota/100',
                  style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enviada em ${formatarDataHora(resposta['enviada_em'])}',
              style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // O texto que o aluno escreveu
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CoresAprendo.superficieClara,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${resposta['conteudo']}', style: const TextStyle(height: 1.5)),
            ),
            if ((resposta['comentario'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Comentário: ${resposta['comentario']}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            // Notas de cada critério da rubrica (quando a IA corrigiu)
            if (criterios is Map) ...[
              const SizedBox(height: 10),
              Text(
                'Conceito ${criterios['conceito']}/50  ·  '
                'Completude ${criterios['completude']}/30  ·  '
                'Clareza ${criterios['clareza']}/20',
                style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context, '${resposta['conteudo']}'),
                icon: const Icon(Icons.edit_note),
                label: const Text('Reaproveitar este texto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
