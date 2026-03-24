import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('leitor não visualiza ações de editar ou excluir',
      (tester) async {
    final repository = ReadingsRepository();
    await repository.saveReading(
      const ReadingInput(
        collectionId: 'collection-1',
        code: '7891234567890',
        source: 'camera',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(
            const CurrentSession(
              userId: 'reader-1',
              activeCompanyId: 'company-a',
              roles: {'reader'},
            ),
          ),
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: ReadingsPage(
            collectionId: 'collection-1',
            collectionTitle: 'Coleta 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('7891234567890'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('operador visualiza ações de editar e excluir', (tester) async {
    final repository = ReadingsRepository();
    await repository.saveReading(
      const ReadingInput(
        collectionId: 'collection-1',
        code: '7891234567890',
        source: 'camera',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(
            const CurrentSession(
              userId: 'operator-1',
              activeCompanyId: 'company-a',
              roles: {'operator'},
            ),
          ),
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: ReadingsPage(
            collectionId: 'collection-1',
            collectionTitle: 'Coleta 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('7891234567890'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
