import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprendo_frontend/main.dart';

void main() {
  testWidgets('O app abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const AprendoApp());

    // Campos e botão principais da tela de login
    expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });
}