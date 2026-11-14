import 'package:flutter/material.dart';

// ============================================================
// CAMPO DE SENHA
// No cadastro (comOlhinho: true) tem o "olhinho" para mostrar ou esconder o que foi digitado.
// No login (comOlhinho: false) a senha fica sempre escondida, sem o olhinho.
// ============================================================
class CampoSenha extends StatefulWidget {
  final TextEditingController controller;
  final String rotulo;
  final String? Function(String?)? validator;
  final String? textoAjuda;
  final ValueChanged<String>? aoEnviar;
  final bool comOlhinho;

  const CampoSenha({
    super.key,
    required this.controller,
    required this.rotulo,
    this.validator,
    this.textoAjuda,
    this.aoEnviar,
    this.comOlhinho = true,
  });

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _oculta = true; // começa escondida, como em qualquer campo de senha

  // O olhinho só funciona com clique do mouse (ou toque). A tecla Tab pula ele,
  // para ninguém revelar a senha sem querer apertando Tab e depois Enter.
  final FocusNode _focoOlhinho = FocusNode(skipTraversal: true, canRequestFocus: false);

  @override
  void dispose() {
    _focoOlhinho.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: widget.validator,
      obscureText: _oculta,
      onFieldSubmitted: widget.aoEnviar,
      decoration: InputDecoration(
        labelText: widget.rotulo,
        border: const OutlineInputBorder(),
        helperText: widget.textoAjuda,
        suffixIcon: widget.comOlhinho
            ? IconButton(
                focusNode: _focoOlhinho,
                icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _oculta = !_oculta),
              )
            : null,
      ),
    );
  }
}
