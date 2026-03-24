import 'package:barcode_app/app/shell/app_shell.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = CurrentSession(
    userId: 'user-1',
    activeCompanyId: 'company-a',
    roles: {'admin'},
    matricula: '9001',
    nome: 'Administrador',
    availableCompanies: [
      CompanyAccess(
        companyId: 'company-a',
        companyCode: 'del-papeis',
        companyName: 'Del Papeis',
        role: 'admin',
      ),
    ],
  );

  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    required String location,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(session),
        ],
        child: MaterialApp(
          home: AppShell(
            currentLocation: location,
            child: const Placeholder(),
          ),
        ),
      ),
    );
  }

  testWidgets('usa navigation rail em telas largas', (tester) async {
    await pumpShell(
      tester,
      size: const Size(1440, 1024),
      location: '/collections',
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Coletas'), findsWidgets);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('usa navigation bar em telas compactas', (tester) async {
    await pumpShell(
      tester,
      size: const Size(390, 844),
      location: '/collections',
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Coletas'), findsWidgets);
  });
}
