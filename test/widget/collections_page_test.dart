import 'package:barcode_app/features/collections/presentation/collections_page.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra a ação de criar coleta', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova coleta'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
  });
}
