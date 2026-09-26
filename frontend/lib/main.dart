import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AprendoApp());
}

class AprendoApp extends StatelessWidget {
  const AprendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprendo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TelaLogin(),
    );
  }
}

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
    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/login'),
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
            MaterialPageRoute(builder: (context) => const TelaPerfil()),
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
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
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
  bool _carregando = false;
  bool _aceitouTermos = false;
  String _mensagem = '';

  Future<void> _cadastrar() async {
    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/cadastro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
          'aceitouTermos': _aceitouTermos,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          _mensagem = 'Cadastro realizado com sucesso! Faça login para continuar.';
        });
        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();
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
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
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
                                color: Colors.deepPurple,
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
                                color: Colors.deepPurple,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                                        onPressed: (_carregando || !_aceitouTermos) ? null : _cadastrar,
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

// ============================================================
// TELA DE PERFIL (área logada, protegida por JWT)
// ============================================================
class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
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
        Uri.parse('http://localhost:3000/perfil'),
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
      body: Center(
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
                          const Icon(Icons.account_circle, size: 100, color: Colors.deepPurple),
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
                                  Text('ID: ${_dadosUsuario!['id']}'),
                                  const SizedBox(height: 8),
                                  Text('Nome: ${_dadosUsuario!['nome']}'),
                                  const SizedBox(height: 8),
                                  Text('E-mail: ${_dadosUsuario!['email']}'),
                                  const SizedBox(height: 8),
                                  Text('Cadastrado em: ${_dadosUsuario!['criado_em']}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
// ============================================================
// TELA DE TERMOS DE USO
// ============================================================
class TelaTermos extends StatefulWidget {
  const TelaTermos({super.key});

  @override
  State<TelaTermos> createState() => _TelaTermosState();
}

class _TelaTermosState extends State<TelaTermos> {
  String _conteudo = '';
  String _versao = '';
  bool _carregando = true;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregarTermos();
  }

  Future<void> _carregarTermos() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/termos'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _conteudo = data['conteudo'];
          _versao = data['versao'];
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = data['error'] ?? 'Erro ao carregar termos';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Termos de Uso ${_versao.isNotEmpty ? "(v$_versao)" : ""}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro.isNotEmpty
              ? Center(child: Text('Erro: $_erro', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _conteudo,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
    );
  }
}
// ============================================================
// TELA DE POLÍTICA DE PRIVACIDADE
// ============================================================
class TelaPolitica extends StatefulWidget {
  const TelaPolitica({super.key});

  @override
  State<TelaPolitica> createState() => _TelaPoliticaState();
}

class _TelaPoliticaState extends State<TelaPolitica> {
  String _conteudo = '';
  String _versao = '';
  bool _carregando = true;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregarPolitica();
  }

  Future<void> _carregarPolitica() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/politica'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _conteudo = data['conteudo'];
          _versao = data['versao'];
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = data['error'] ?? 'Erro ao carregar política';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Política de Privacidade ${_versao.isNotEmpty ? "(v$_versao)" : ""}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro.isNotEmpty
              ? Center(child: Text('Erro: $_erro', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _conteudo,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
    );
  }
}