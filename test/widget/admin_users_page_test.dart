import 'package:barcode_app/features/admin/presentation/admin_users_page.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o formulario administrativo de criacao de usuario',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(
            const CurrentSession(
              userId: 'admin-1',
              activeCompanyId: 'company-a',
              roles: {'admin'},
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdminUsersPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Criar usuario'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Matricula'), findsOneWidget);
    expect(find.text('Senha inicial'), findsOneWidget);
    expect(find.text('Cargo global'), findsOneWidget);
    expect(find.text('Del Papeis'), findsOneWidget);
    expect(find.text('Bora Embalagens'), findsOneWidget);
    expect(find.text('ABN Embalagens'), findsOneWidget);
  });
}
