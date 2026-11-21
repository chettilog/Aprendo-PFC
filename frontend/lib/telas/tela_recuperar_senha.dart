import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../componentes/campo_senha.dart';
import '../tema.dart';
import '../validacoes.dart';

// ============================================================
// RECUPERAÇÃO DE SENHA
// Duas etapas:
//   1. O aluno informa o e-mail -> POST /senha/esqueci (o servidor envia um código de 6 dígitos)
//   2. Informa o código e a nova senha -> POST /senha/redefinir
// O servidor responde igual exista ou não a conta, para não revelar quem está cadastrado.
// O código vale 15 minutos, serve uma vez só e aceita no máximo 5 tentativas.
// ============================================================
class TelaRecuperarSenha extends StatefulWidget {
  final String emailInicial;

  const TelaRecuperarSenha({super.key, this.emailInicial = ''});

  @override
  State<TelaRecuperarSenha> createState() => _TelaRecuperarSenhaState();
}

class _TelaRecuperarSenhaState extends State<TelaRecuperarSenha> {
  final _formEmail = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _codigoEnviado = false; // false = etapa 1 (e-mail), true = etapa 2 (código e nova senha)
  bool _carregando = false;
  String? _aviso; // mensagem informativa (verde)
  String? _erro; // mensagem de erro (vermelha)

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  String _mensagemDe(Object e) =>
      e is ApiErro ? e.mensagem : 'Não foi possível conectar ao servidor. Tente de novo.';

  // Etapa 1: pede o código (também usado no "Reenviar código")
  Future<void> _pedirCodigo() async {
    // Na etapa 2 o formulário do e-mail não está na tela: o e-mail já foi validado antes
    if (!_codigoEnviado && !_formEmail.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
      _aviso = null;
    });
    try {
      final resposta = await apiPost('/senha/esqueci', {'email': _emailController.text.trim()});
      setState(() {
        _codigoEnviado = true;
        _aviso = resposta is Map ? '${resposta['message']}' : 'Código enviado.';
      });
    } catch (e) {
      setState(() => _erro = _mensagemDe(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Etapa 2: confere o código e cria a nova senha
  Future<void> _redefinir() async {
    if (!_formCodigo.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await apiPost('/senha/redefinir', {
        'email': _emailController.text.trim(),
        'codigo': _codigoController.text.trim(),
        'novaSenha': _novaSenhaController.text,
      });
      // Volta para o login, que mostra o aviso de sucesso
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erro = _mensagemDe(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _trocarEmail() {
    setState(() {
      _codigoEnviado = false;
      _aviso = null;
      _erro = null;
      _codigoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_codigoEnviado) _etapaEmail() else _etapaCodigo(),
                if (_aviso != null) ...[
                  const SizedBox(height: 16),
                  Text(_aviso!, textAlign: TextAlign.center, style: const TextStyle(color: CoresAprendo.turquesa)),
                ],
                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: CoresAprendo.erro)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _etapaEmail() {
    return Form(
      key: _formEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o e-mail da sua conta. Vamos enviar um código de 6 dígitos para você criar uma nova senha.',
            style: TextStyle(color: CoresAprendo.textoSuave),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            validator: validarEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
            onFieldSubmitted: (_) {
              if (!_carregando) _pedirCodigo();
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _carregando ? null : _pedirCodigo,
            child: _carregando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  Widget _etapaCodigo() {
    return Form(
      key: _formCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Digite o código enviado para ${_emailController.text.trim()} e escolha a nova senha. '
            'O código vale por 15 minutos.',
            style: const TextStyle(color: CoresAprendo.textoSuave),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codigoController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (valor) =>
                (valor == null || valor.trim().length != 6) ? 'O código tem 6 dígitos' : null,
            decoration: const InputDecoration(labelText: 'Código', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          CampoSenha(
            controller: _novaSenhaController,
            rotulo: 'Nova senha',
            validator: validarSenha,
          ),
          const SizedBox(height: 16),
          CampoSenha(
            controller: _confirmacaoController,
            rotulo: 'Confirme a nova senha',
            validator: (valor) => validarConfirmacaoSenha(_novaSenhaController.text, valor),
            aoEnviar: (_) {
              if (!_carregando) _redefinir();
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _carregando ? null : _redefinir,
            child: _carregando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('Criar nova senha'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: _carregando ? null : _trocarEmail, child: const Text('Usar outro e-mail')),
              TextButton(onPressed: _carregando ? null : _pedirCodigo, child: const Text('Reenviar código')),
            ],
          ),
        ],
      ),
    );
  }
}
