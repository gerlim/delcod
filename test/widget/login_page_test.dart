import 'package:barcode_app/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra os campos Empresa, Matrícula e Senha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onSubmit: (_) async {},
        ),
      ),
    );

    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Matrícula'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
