import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../componentes/campo_senha.dart';
import '../tema.dart';
import '../validacoes.dart';
import 'tela_documentos.dart';

// ============================================================
// TELA DE CADASTRO
// ============================================================
class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _carregando = false;
  bool _aceitouTermos = false;
  bool _idadeMinima = false; // declaração de que tem 12 anos ou mais (LGPD, Art. 14)
  String _mensagem = '';

  Future<void> _cadastrar() async {
    final erro = validarNome(_nomeController.text) ??
        validarEmail(_emailController.text) ??
        validarSenha(_senhaController.text) ??
        validarConfirmacaoSenha(_senhaController.text, _confirmacaoController.text);
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
        Uri.parse('$apiBase/cadastro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
          'aceitouTermos': _aceitouTermos,
          'idadeMinima': _idadeMinima,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          _mensagem = 'Cadastro realizado com sucesso! Faça login para continuar.';
        });
       
      } else {
        setState(() {
          _mensagem = 'Erro: ${data['error'] ?? 'Falha no cadastro'}';
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
        title: const Text('Aprendo - Cadastro'),
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
                  'Crie sua conta',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nomeController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validarNome,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
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
                  validator: validarSenha,
                  textoAjuda: 'Mínimo de 6 caracteres',
                ),
                const SizedBox(height: 16),
                CampoSenha(
                  controller: _confirmacaoController,
                  rotulo: 'Confirme sua senha',
                  validator: (valor) =>
                      validarConfirmacaoSenha(_senhaController.text, valor),
                ),
                const SizedBox(height: 24),
                // Declaração de idade mínima (obrigatória - LGPD, Art. 14).
                // Só a declaração é guardada, sem data de nascimento (minimização de dados).
                Row(
                  children: [
                    Checkbox(
                      value: _idadeMinima,
                      onChanged: (valor) {
                        setState(() {
                          _idadeMinima = valor ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text('Tenho 12 anos ou mais', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                // Checkbox de aceite dos Termos e Política (obrigatório - LGPD)
                Row(
                  children: [
                    Checkbox(
                      value: _aceitouTermos,
                      onChanged: (valor) {
                        setState(() {
                          _aceitouTermos = valor ?? false;
                        });
                      },
                    ),
                     Expanded(
                      child: Wrap(
                        children: [
                          const Text('Li e aceito os ', style: TextStyle(fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TelaTermos()),
                              );
                            },
                            child: const Text(
                              'Termos de Uso',
                              style: TextStyle(
                                fontSize: 13,
                                color: CoresAprendo.turquesa,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Text(' e a ', style: TextStyle(fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TelaPolitica()),
                              );
                            },
                            child: const Text(
                              'Política de Privacidade',
                              style: TextStyle(
                                fontSize: 13,
                                color: CoresAprendo.turquesa,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Se você tem menos de 18 anos, leia os termos junto com um responsável.',
                      style: TextStyle(fontSize: 12, color: CoresAprendo.textoSuave),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_carregando || !_aceitouTermos || !_idadeMinima)
                        ? null
                        : _cadastrar,
                    child: _carregando
                        ? const CircularProgressIndicator()
                        : const Text('Cadastrar'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Já tem conta? Faça login'),
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
