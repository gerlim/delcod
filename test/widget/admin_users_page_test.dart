import 'package:barcode_app/features/admin/presentation/admin_users_page.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o formulário administrativo de criação de usuário',
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

    expect(find.text('Criar usuário'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Matrícula'), findsOneWidget);
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Papéis'), findsOneWidget);
    expect(find.text('Cargo global'), findsOneWidget);
  });
}
