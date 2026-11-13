import 'package:flutter/material.dart';

// ============================================================
// CAMPO DE SENHA com o "olhinho" para mostrar ou esconder o que foi digitado.
// Usado no login e no cadastro (senha e confirmação).
// ============================================================
class CampoSenha extends StatefulWidget {
  final TextEditingController controller;
  final String rotulo;
  final String? Function(String?)? validator;
  final String? textoAjuda;
  final ValueChanged<String>? aoEnviar;

  const CampoSenha({
    super.key,
    required this.controller,
    required this.rotulo,
    this.validator,
    this.textoAjuda,
    this.aoEnviar,
  });

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _oculta = true; // começa escondida, como em qualquer campo de senha

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
        suffixIcon: IconButton(
          icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}
