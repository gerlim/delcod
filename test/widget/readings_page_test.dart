// ignore_for_file: prefer_const_constructors

import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o total inicial da lista global', (tester) async {
    final repository = _StaticReadingsRepository(
      items: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsOneWidget);
    expect(find.text('Bobinas ativas'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.text('Importar arquivo'), findsOneWidget);
    expect(find.text('Alocar armazem'), findsOneWidget);
    expect(find.text('Exportar XLSX'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });

  testWidgets(
      'em telas largas posiciona a lista a direita do painel operacional',
      (tester) async {
    final repository = _StaticReadingsRepository(
      items: [
        ReadingItem(
          id: '1',
          code: '789123',
          source: 'manual',
          updatedAt: DateTime.parse('2026-03-25T22:40:00Z'),
          deletedAt: null,
          deviceId: 'web',
          metadataPayload: const {
            'warehouse_code': '05',
            'warehouse_company': 'Bora Embalagens',
            'bobbin_lot': '789123',
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inputCardFinder = find.ancestor(
      of: find.text('Entrada manual'),
      matching: find.byType(Card),
    );
    final listCardFinder = find.ancestor(
      of: find.text('Lista global'),
      matching: find.byType(Card),
    );

    expect(find.text('Acoes da lista'), findsOneWidget);
    expect(inputCardFinder, findsOneWidget);
    expect(listCardFinder, findsOneWidget);
    expect(find.text('Lote de Bobina'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Armazem'), findsAtLeastNWidgets(1));
    expect(
      tester.getTopLeft(listCardFinder).dx,
      greaterThan(tester.getTopLeft(inputCardFinder).dx + 300),
    );
  });

  testWidgets('no mobile mostra secoes separadas para resumo e acoes',
      (tester) async {
    final repository = _StaticReadingsRepository(
      items: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: true,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Acoes da lista'),
      300,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo rapido', skipOffstage: false), findsOneWidget);
    expect(find.text('Acoes da lista'), findsOneWidget);
  });
}

class _StaticReadingsRepository implements ReadingsRepository {
  const _StaticReadingsRepository({
    required this.items,
  });

  final List<ReadingItem> items;

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> checkOnlineStatus() async => true;

  @override
  Future<void> clearAll() async {}

  @override
  void dispose() {}

  @override
  Future<bool> existsCode(
    String code, {
    String? excludingId,
  }) async {
    return false;
  }

  @override
  Future<List<ReadingItem>> fetchActive() async => items;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> syncNow() async {}

  @override
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {}

  @override
  Stream<List<ReadingItem>> watchActive() => Stream.value(items);

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
