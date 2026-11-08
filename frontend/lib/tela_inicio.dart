import 'package:flutter/material.dart';
import 'main.dart';
import 'tela_trilhas.dart';
import 'tela_painel.dart';

// ============================================================
// TELA INICIAL: barra de navegação com Início, Trilhas e Perfil
// ============================================================
class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    // Cada aba é recriada ao ser aberta, para mostrar sempre os dados atualizados
    final Widget conteudo = switch (_aba) {
      0 => const TelaPainel(),
      1 => const TelaTrilhas(),
      _ => const TelaPerfil(),
    };

    return Scaffold(
      body: conteudo,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (indice) => setState(() => _aba = indice),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trilhas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

