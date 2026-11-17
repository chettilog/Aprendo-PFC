import 'package:flutter/material.dart';
import '../tema.dart';

// ============================================================
// AVATARES DO PERFIL
// O aluno escolhe um dos 12 avatares prontos (ícone + cor). O banco guarda só o
// número (0 a 11). Não há envio de foto: assim o sistema não guarda imagem do rosto
// de alunos, muitos deles menores de idade (LGPD, art. 14).
// ============================================================
class OpcaoAvatar {
  final IconData icone;
  final Color cor;
  final String nome;

  const OpcaoAvatar(this.icone, this.cor, this.nome);
}

const opcoesDeAvatar = <OpcaoAvatar>[
  OpcaoAvatar(Icons.face_rounded, Color(0xFF3FD9C7), 'Rosto'),
  OpcaoAvatar(Icons.rocket_launch_rounded, Color(0xFFF2B84B), 'Foguete'),
  OpcaoAvatar(Icons.pets_rounded, Color(0xFFFF8A65), 'Patinha'),
  OpcaoAvatar(Icons.sports_esports_rounded, Color(0xFF9C8CFF), 'Controle'),
  OpcaoAvatar(Icons.music_note_rounded, Color(0xFFFF6FAE), 'Música'),
  OpcaoAvatar(Icons.science_rounded, Color(0xFF66D17A), 'Ciência'),
  OpcaoAvatar(Icons.psychology_rounded, Color(0xFF5EB8FF), 'Ideias'),
  OpcaoAvatar(Icons.local_florist_rounded, Color(0xFFB4E05A), 'Flor'),
  OpcaoAvatar(Icons.bolt_rounded, Color(0xFFFFD54F), 'Raio'),
  OpcaoAvatar(Icons.menu_book_rounded, Color(0xFFE57373), 'Livro'),
  OpcaoAvatar(Icons.public_rounded, Color(0xFF4DD0E1), 'Planeta'),
  OpcaoAvatar(Icons.sports_soccer_rounded, Color(0xFFAED581), 'Bola'),
];

// Converte o valor que vem da API em um número de avatar válido (0 se vier algo estranho)
int indiceDoAvatar(Object? valor) {
  final numero = valor is num ? valor.toInt() : 0;
  return (numero >= 0 && numero < opcoesDeAvatar.length) ? numero : 0;
}

// Círculo colorido com o ícone do avatar
class AvatarAprendo extends StatelessWidget {
  final int indice;
  final double tamanho;

  const AvatarAprendo({super.key, required this.indice, this.tamanho = 48});

  @override
  Widget build(BuildContext context) {
    final opcao = opcoesDeAvatar[indiceDoAvatar(indice)];
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(color: opcao.cor, shape: BoxShape.circle),
      child: Icon(opcao.icone, size: tamanho * 0.58, color: CoresAprendo.fundo),
    );
  }
}

// Grade para escolher o avatar; o selecionado ganha uma borda dourada
class EscolhaDeAvatar extends StatelessWidget {
  final int selecionado;
  final ValueChanged<int>? aoEscolher;

  const EscolhaDeAvatar({super.key, required this.selecionado, required this.aoEscolher});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < opcoesDeAvatar.length; i++)
          Tooltip(
            message: opcoesDeAvatar[i].nome,
            child: InkWell(
              key: ValueKey('avatar_$i'),
              customBorder: const CircleBorder(),
              onTap: aoEscolher == null ? null : () => aoEscolher!(i),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == selecionado ? CoresAprendo.ouro : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: AvatarAprendo(indice: i, tamanho: 52),
              ),
            ),
          ),
      ],
    );
  }
}
