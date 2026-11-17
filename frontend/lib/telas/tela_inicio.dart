import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tela_admin.dart';
import 'tela_dashboard.dart';
import 'tela_painel.dart';
import 'tela_perfil.dart';
import 'tela_ranking.dart';
import 'tela_trilhas.dart';

// ============================================================
// TELA INICIAL: barra de navegação com Início, Trilhas, Dashboard, Ranking e Perfil.
// Contas admin também veem a aba Admin (visão geral e logs).
// ============================================================
class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _aba = 0;
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    _verificarPerfil();
  }

  // O perfil foi salvo no login. Ele só esconde ou mostra a aba:
  // se alguém forçar a aba, o servidor responde 403 do mesmo jeito.
  Future<void> _verificarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _admin = prefs.getString('perfil_usuario') == 'admin');
  }

  @override
  Widget build(BuildContext context) {
    // Cada aba é recriada ao ser aberta, para mostrar sempre os dados atualizados
    final Widget conteudo = switch (_aba) {
      0 => const TelaPainel(),
      1 => const TelaTrilhas(),
      2 => const TelaDashboard(),
      3 => const TelaRanking(),
      4 => const TelaPerfil(),
      _ => const TelaAdmin(),
    };

    return Scaffold(
      body: conteudo,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (indice) => setState(() => _aba = indice),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trilhas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Ranking',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          if (_admin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
