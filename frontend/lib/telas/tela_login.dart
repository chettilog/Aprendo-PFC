import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../componentes/campo_senha.dart';
import '../validacoes.dart';
import 'tela_cadastro.dart';
import 'tela_inicio.dart';

// ============================================================
// TELA DE LOGIN
// ============================================================
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String _mensagem = '';

  Future<void> _fazerLogin() async {
    final erro = validarEmail(_emailController.text) ??
        validarSenhaLogin(_senhaController.text);
    if (erro != null) {
      setState(() => _mensagem = 'Erro: $erro');
      return;
    }
    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'senha': _senhaController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Salva o token no armazenamento local do navegador
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nome_usuario', data['usuario']['nome']);

        // Navega pra tela de perfil
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TelaInicio()),
          );
        }
      } else {
        setState(() {
          _mensagem = 'Erro: ${data['error'] ?? 'Falha no login'}';
        });
      }
    } catch (e) {
      setState(() {
        _mensagem = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprendo - Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validarEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                CampoSenha(
                  controller: _senhaController,
                  rotulo: 'Senha',
                  validator: validarSenhaLogin,
                  comOlhinho: false, // no login a senha nunca é mostrada
                  aoEnviar: (_) {
                    if (!_carregando) _fazerLogin();
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const CircularProgressIndicator()
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaCadastro(),
                      ),
                    );
                  },
                  child: const Text('Ainda não tem conta? Cadastre-se'),
                ),
                const SizedBox(height: 16),
                if (_mensagem.isNotEmpty)
                  Text(
                    _mensagem,
                    style: TextStyle(
                      color: _mensagem.startsWith('Erro') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
