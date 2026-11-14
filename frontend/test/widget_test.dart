import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprendo_frontend/main.dart';
import 'package:aprendo_frontend/telas/tela_cadastro.dart';
import 'package:aprendo_frontend/telas/tela_trilhas.dart';
import 'package:aprendo_frontend/validacoes.dart';

void main() {
  testWidgets('O app abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const AprendoApp());

    // Campos e botão principais da tela de login
    expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('No login a senha fica escondida e não tem olhinho', (WidgetTester tester) async {
    await tester.pumpWidget(const AprendoApp());

    final campoSenha = tester.widget<TextField>(find.widgetWithText(TextField, 'Senha'));
    expect(campoSenha.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('No cadastro o olhinho mostra e esconde a senha', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaCadastro()));

    bool escondida(String rotulo) =>
        tester.widget<TextField>(find.widgetWithText(TextField, rotulo)).obscureText;

    expect(escondida('Senha'), isTrue);
    expect(escondida('Confirme sua senha'), isTrue);

    // Clica no olhinho do primeiro campo (Senha)
    final olhinho = find.byIcon(Icons.visibility_outlined).first;
    await tester.ensureVisible(olhinho);
    await tester.pumpAndSettle();
    await tester.tap(olhinho);
    await tester.pump();

    expect(escondida('Senha'), isFalse);
    expect(escondida('Confirme sua senha'), isTrue); // o outro campo continua escondido
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

  testWidgets('O cadastro só libera o botão com idade mínima e termos marcados',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaCadastro()));

    bool botaoLiberado() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Cadastrar')).onPressed != null;

    expect(find.text('Tenho 12 anos ou mais'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(botaoLiberado(), isFalse);

    // Marca só a idade: ainda bloqueado
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(botaoLiberado(), isFalse);

    // Marca também os termos: liberado
    await tester.ensureVisible(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(botaoLiberado(), isTrue);
  });

  test('Cada matéria tem o seu ícone', () {
    expect(iconeDaMateria('Matemática'), Icons.calculate_rounded);
    expect(iconeDaMateria('História'), Icons.account_balance_rounded);
    expect(iconeDaMateria('Geografia'), Icons.public_rounded);
    expect(iconeDaMateria('Outra matéria'), Icons.menu_book_rounded);
  });

  test('validarConfirmacaoSenha', () {
    expect(validarConfirmacaoSenha('123456', ''), 'Confirme a sua senha');
    expect(validarConfirmacaoSenha('123456', '123457'), 'As senhas não são iguais');
    expect(validarConfirmacaoSenha('123456', '123456'), isNull);
  });
}
