import 'package:barcode_app/features/collections/presentation/collections_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('mostra a ação de criar coleta', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );

    expect(find.text('Nova coleta'), findsOneWidget);
  });
}
