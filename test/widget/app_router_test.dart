import 'package:barcode_app/app/router/app_router.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre direto na tela principal simplificada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(
            _RouterReadingsRepository(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: buildRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
  });
}

class _RouterReadingsRepository implements ReadingsRepository {
  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
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
    return false;
  }

  @override
  Future<List<ReadingItem>> fetchActive() async => const [];

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
  Stream<List<ReadingItem>> watchActive() => const Stream.empty();

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
