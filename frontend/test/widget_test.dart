import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprendo_frontend/main.dart';
import 'package:aprendo_frontend/telas/tela_cadastro.dart';
import 'package:aprendo_frontend/validacoes.dart';

void main() {
  testWidgets('O app abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const AprendoApp());

    // Campos e botão principais da tela de login
    expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('O olhinho mostra e esconde a senha no login', (WidgetTester tester) async {
    await tester.pumpWidget(const AprendoApp());

    TextField campoSenha() =>
        tester.widget<TextField>(find.widgetWithText(TextField, 'Senha'));

    expect(campoSenha().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(campoSenha().obscureText, isFalse);
  });

  testWidgets('O cadastro pede a confirmação da senha', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaCadastro()));

    expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirme sua senha'), findsOneWidget);
    // um olhinho em cada campo de senha
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

    await tester.enterText(find.widgetWithText(TextField, 'Senha'), '123456');
    await tester.enterText(find.widgetWithText(TextField, 'Confirme sua senha'), '654321');
    await tester.pump();
    expect(find.text('As senhas não são iguais'), findsOneWidget);
  });

  test('validarConfirmacaoSenha', () {
    expect(validarConfirmacaoSenha('123456', ''), 'Confirme a sua senha');
    expect(validarConfirmacaoSenha('123456', '123457'), 'As senhas não são iguais');
    expect(validarConfirmacaoSenha('123456', '123456'), isNull);
  });
}
