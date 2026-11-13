import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../tema.dart';
import 'tela_busca_wiki.dart';
import 'tela_documentos.dart';
import 'tela_login.dart';

// ============================================================
// TELA DE PERFIL (área logada, protegida por JWT)
// ============================================================
class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

// O identificador interno da conta não aparece na tela (pedido da banca):
// ele só serve para o sistema, não para o aluno.
String _nomeDoPerfil(dynamic perfil) => perfil == 'admin' ? 'Administrador' : 'Aluno';

// "2026-11-13T15:20:00.000Z" -> "13/11/2026"
String _formatarData(dynamic valor) {
  final data = DateTime.tryParse('${valor ?? ''}')?.toLocal();
  if (data == null) return '-';
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}

class _TelaPerfilState extends State<TelaPerfil> {
  Map<String, dynamic>? _dadosUsuario;
  bool _carregando = true;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _erro = 'Você precisa fazer login';
          _carregando = false;
        });
        return;
      }

      // Chama a rota protegida enviando o token no cabeçalho
      final response = await http.get(
        Uri.parse('$apiBase/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _dadosUsuario = data['usuario'];
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = data['error'] ?? 'Erro ao carregar perfil';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro de conexão: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _fazerLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nome_usuario');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaLogin()),
      );
    }
  }
    Future<void> _excluirConta() async {
    // Diálogo de confirmação (LGPD: evita exclusão acidental)
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita. '
          'Seus dados pessoais serão removidos, e você não conseguirá mais acessar a plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('$apiBase/minha-conta'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Limpa o token e volta pra tela de login
        await prefs.remove('token');
        await prefs.remove('nome_usuario');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta excluída com sucesso')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TelaLogin()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir conta')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprendo - Meu Perfil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _fazerLogout,
          ),
        ],
      ),
            body: SingleChildScrollView(child: Center(
        child: _carregando
            ? const CircularProgressIndicator()
            : _erro.isNotEmpty
                ? Text('Erro: $_erro', style: const TextStyle(color: Colors.red))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_circle, size: 100, color: CoresAprendo.turquesa),
                          const SizedBox(height: 24),
                          Text(
                            'Bem-vindo, ${_dadosUsuario!['nome']}!',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nome: ${_dadosUsuario!['nome']}'),
                                  const SizedBox(height: 8),
                                  Text('E-mail: ${_dadosUsuario!['email']}'),
                                  const SizedBox(height: 8),
                                  Text('Tipo de conta: ${_nomeDoPerfil(_dadosUsuario!['perfil'])}'),
                                  const SizedBox(height: 8),
                                  Text('Cadastrado em: ${_formatarData(_dadosUsuario!['criado_em'])}'),
                                ],
                              ),
                            ),
                          ),
                                                    const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TelaBuscaWiki(),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(Icons.search),
                            label: const Text('Explorar conteúdo'),
                          ),
                                                    const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Documentos legais',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TelaTermos()),
                                  );
                                },
                                icon: const Icon(Icons.description_outlined, size: 18),
                                label: const Text('Termos de Uso'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TelaPolitica()),
                                  );
                                },
                                icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                                label: const Text('Política de Privacidade'),
                              ),
                            ],
                          ),
                                                    const SizedBox(height: 32),
                          // Seção LGPD: direito à exclusão da conta (Art. 18 da LGPD)
                          OutlinedButton.icon(
                            onPressed: _excluirConta,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Excluir minha conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
              ),
    );
  }
}
