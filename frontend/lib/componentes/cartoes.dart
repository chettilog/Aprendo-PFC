import 'package:flutter/material.dart';
import '../tema.dart';

// ============================================================
// PEÇAS VISUAIS REUTILIZADAS pelas telas Início, Dashboard e Respostas anteriores
// ============================================================

// Cor, ícone e nome de cada resultado da correção
(Color, IconData, String) aparenciaDoResultado(dynamic resultado) => switch (resultado) {
      'suficiente' => (CoresAprendo.turquesa, Icons.check_circle, 'Suficiente'),
      'parcial' => (CoresAprendo.ouro, Icons.lightbulb, 'Parcial'),
      _ => (CoresAprendo.erro, Icons.refresh, 'Insuficiente'),
    };

// Cartão com título, usado para agrupar cada bloco de informação
class Secao extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;

  const Secao({super.key, required this.titulo, this.subtitulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(subtitulo!, style: const TextStyle(color: CoresAprendo.textoSuave, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// Indicador em destaque: ícone, número grande e legenda
class NumeroGrande extends StatelessWidget {
  final String valor;
  final String rotulo;
  final IconData icone;
  final Color cor;

  const NumeroGrande({
    super.key,
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

// Organiza os indicadores em colunas: mais colunas em telas largas, 2 no celular
class GradeNumeros extends StatelessWidget {
  final List<Widget> numeros;
  final int colunasTelaLarga;

  const GradeNumeros({super.key, required this.numeros, this.colunasTelaLarga = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        const espaco = 12.0;
        final colunas = limites.maxWidth >= 640 ? colunasTelaLarga : 2;
        final largura = ((limites.maxWidth - espaco * (colunas - 1)) / colunas).floorToDouble();
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
