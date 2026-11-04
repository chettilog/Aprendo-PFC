// Validações dos formulários (mesmas regras do back-end)

final _regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validarNome(String? valor) {
  final nome = (valor ?? '').trim();
  if (nome.isEmpty) return 'Informe o seu nome';
  if (nome.length < 2 || nome.length > 100) {
    return 'O nome deve ter entre 2 e 100 caracteres';
  }
  return null;
}

String? validarEmail(String? valor) {
  final email = (valor ?? '').trim();
  if (email.isEmpty) return 'Informe o seu e-mail';
  if (email.length > 100 || !_regexEmail.hasMatch(email)) {
    return 'Informe um e-mail válido';
  }
  return null;
}

String? validarSenha(String? valor) {
  final senha = valor ?? '';
  if (senha.isEmpty) return 'Informe a sua senha';
  if (senha.length < 6 || senha.length > 72) {
    return 'A senha deve ter entre 6 e 72 caracteres';
  }
  return null;
}

// No login só exige o preenchimento (as regras de tamanho valem no cadastro)
String? validarSenhaLogin(String? valor) {
  if ((valor ?? '').isEmpty) return 'Informe a sua senha';
  return null;
}