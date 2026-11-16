import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../componentes/campo_senha.dart';
import '../tema.dart';
import '../validacoes.dart';
import 'tela_trilhas.dart';

// ============================================================
// EDITAR PERFIL (RF15)
// Duas partes independentes:
//   1. Trocar o nome  -> PUT /perfil
//   2. Trocar a senha -> PUT /perfil/senha (exige a senha atual)
// O e-mail não é editável, porque é o dado de acesso à conta.
// Ao voltar, a tela de perfil recarrega os dados.
// ============================================================
class TelaEditarPerfil extends StatefulWidget {
  final String nomeAtual;
  final String email;

  const TelaEditarPerfil({super.key, required this.nomeAtual, required this.email});

  @override
  State<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends State<TelaEditarPerfil> {
  final _formNome = GlobalKey<FormState>();
  final _formSenha = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _salvandoNome = false;
  bool _salvandoSenha = false;
  String? _erroNome;
  String? _erroSenha;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeAtual);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _mensagem(Object erro) => ehSessaoExpirada(erro)
      ? 'Sua sessão expirou. Saia e entre novamente.'
      : mensagemDeErro(erro);

  Future<void> _salvarNome() async {
    if (!_formNome.currentState!.validate()) return;
    setState(() {
      _salvandoNome = true;
      _erroNome = null;
    });
    try {
      final dados = await apiPut('/perfil', {'nome': _nomeController.text.trim()});
      // O nome também fica salvo no aparelho, para a saudação da tela Início
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nome_usuario', '${dados['usuario']['nome']}');
      if (mounted) _avisar('Nome atualizado!');
    } catch (e) {
      if (mounted) setState(() => _erroNome = _mensagem(e));
    } finally {
      if (mounted) setState(() => _salvandoNome = false);
    }
  }

  Future<void> _salvarSenha() async {
    if (!_formSenha.currentState!.validate()) return;
    setState(() {
      _salvandoSenha = true;
      _erroSenha = null;
    });
    try {
      await apiPut('/perfil/senha', {
        'senhaAtual': _senhaAtualController.text,
        'novaSenha': _novaSenhaController.text,
      });
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmacaoController.clear();
      _formSenha.currentState!.reset();
      if (mounted) _avisar('Senha alterada!');
    } catch (e) {
      if (mounted) setState(() => _erroSenha = _mensagem(e));
    } finally {
      if (mounted) setState(() => _salvandoSenha = false);
    }
  }

  Widget _botao({required bool carregando, required VoidCallback aoClicar, required String texto}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: carregando ? null : aoClicar,
        child: carregando
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3))
            : Text(texto),
      ),
    );
  }

  Widget _erro(String? mensagem) => mensagem == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(mensagem, style: const TextStyle(color: CoresAprendo.erro)),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ---------- Nome ----------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formNome,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dados da conta',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomeController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: validarNome,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: widget.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              helperText: 'O e-mail é usado para entrar e não pode ser alterado.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _botao(carregando: _salvandoNome, aoClicar: _salvarNome, texto: 'Salvar nome'),
                          _erro(_erroNome),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ---------- Senha ----------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formSenha,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trocar senha',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          CampoSenha(
                            controller: _senhaAtualController,
                            rotulo: 'Senha atual',
                            validator: validarSenhaLogin,
                          ),
                          const SizedBox(height: 16),
                          CampoSenha(
                            controller: _novaSenhaController,
                            rotulo: 'Nova senha',
                            validator: validarSenha,
                            textoAjuda: 'Mínimo de 6 caracteres',
                          ),
                          const SizedBox(height: 16),
                          CampoSenha(
                            controller: _confirmacaoController,
                            rotulo: 'Confirme a nova senha',
                            validator: (valor) =>
                                validarConfirmacaoSenha(_novaSenhaController.text, valor),
                          ),
                          const SizedBox(height: 16),
                          _botao(carregando: _salvandoSenha, aoClicar: _salvarSenha, texto: 'Trocar senha'),
                          _erro(_erroSenha),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
