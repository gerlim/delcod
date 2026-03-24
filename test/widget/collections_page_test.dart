import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:barcode_app/features/collections/presentation/collections_page.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = CurrentSession(
    userId: 'operator-1',
    activeCompanyId: 'company-a',
    roles: {'operator'},
    matricula: '1001',
    nome: 'Operador',
    availableCompanies: [
      CompanyAccess(
        companyId: 'company-a',
        companyCode: 'del-papeis',
        companyName: 'Del Papeis',
        role: 'operator',
      ),
    ],
  );

  testWidgets('mostra estado vazio inicial da lista de coletas', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(session),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma coleta criada'), findsOneWidget);
    expect(find.text('Nova coleta'), findsOneWidget);
  });

  testWidgets('cria uma coleta e abre o detalhe automaticamente',
      (tester) async {
    CollectionItem? openedCollection;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(session),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          home: CollectionsPage(
            onOpenCollection: (collection) async {
              openedCollection = collection;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova coleta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Expedicao da manha',
    );
    await tester.tap(find.text('Criar coleta'));
    await tester.pumpAndSettle();

    expect(openedCollection, isNotNull);
    expect(openedCollection?.title, 'Expedicao da manha');
    expect(find.text('Expedicao da manha'), findsOneWidget);
  });
}
