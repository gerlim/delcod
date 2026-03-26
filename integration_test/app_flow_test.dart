import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renderiza a tela principal simplificada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(
            _IntegrationReadingsRepository(),
          ),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: ReadingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsOneWidget);
    expect(find.text('Codigos ativos'), findsOneWidget);
    expect(find.text('Exportar XLSX'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });
}

class _IntegrationReadingsRepository implements ReadingsRepository {
  final List<ReadingItem> _items = [
    ReadingItem(
      id: '1',
      code: '7891234567890',
      source: 'camera',
      updatedAt: DateTime.parse('2026-03-23T13:30:00Z'),
      deletedAt: null,
      deviceId: 'android',
    ),
  ];

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
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
    return _items.any((item) => item.code == code && item.id != excludingId);
  }

  @override
  Future<List<ReadingItem>> fetchActive() async => List<ReadingItem>.of(_items);

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
  }) async {}

  @override
  Stream<List<ReadingItem>> watchActive() => Stream.value(_items);

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
