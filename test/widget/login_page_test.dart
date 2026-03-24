import 'package:barcode_app/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra selecao fixa de empresa, matricula e senha',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onSubmit: (_) async {},
        ),
      ),
    );

    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Matricula'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });

  testWidgets('lista as empresas fixas no seletor de login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onSubmit: (_) async {},
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Del Papeis'), findsWidgets);
    expect(find.text('Bora Embalagens'), findsWidgets);
    expect(find.text('ABN Embalagens'), findsWidgets);
  });
}
