import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('mostra o total inicial da coleta', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          home: ReadingsPage(
            collectionId: 'collection-1',
            collectionTitle: 'Coleta 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total: 0'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.text('Exportar XLSX'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });
}
