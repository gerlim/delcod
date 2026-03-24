import 'package:barcode_app/app/router/app_router.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const readerSession = CurrentSession(
    userId: 'reader-1',
    activeCompanyId: 'company-a',
    roles: {'reader'},
    matricula: '1001',
    nome: 'Leitor',
    availableCompanies: [
      CompanyAccess(
        companyId: 'company-a',
        companyCode: 'del-papeis',
        companyName: 'Del Papeis',
        role: 'reader',
      ),
    ],
  );

  const managerSession = CurrentSession(
    userId: 'manager-1',
    activeCompanyId: 'company-a',
    roles: {'manager'},
    matricula: '2001',
    nome: 'Gestor',
    availableCompanies: [
      CompanyAccess(
        companyId: 'company-a',
        companyCode: 'del-papeis',
        companyName: 'Del Papeis',
        role: 'manager',
      ),
    ],
  );

  Widget buildTestApp({
    CurrentSession? session,
    required String initialLocation,
  }) {
    return ProviderScope(
      overrides: [
        currentSessionProvider.overrideWithValue(session),
        syncPollingEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        routerConfig: buildRouter(initialLocation: initialLocation),
      ),
    );
  }

  testWidgets('mostra login ao acessar rota autenticada sem sessao',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        initialLocation: '/collections',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Matricula'), findsOneWidget);
  });

  testWidgets('bloqueia rota administrativa para leitor', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        session: readerSession,
        initialLocation: '/admin',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acesso negado'), findsOneWidget);
    expect(find.text('Administracao'), findsNothing);
  });

  testWidgets('permite auditoria para gestor', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        session: managerSession,
        initialLocation: '/audit',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auditoria'), findsWidgets);
  });
}
