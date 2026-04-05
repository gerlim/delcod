import 'package:barcode_app/app/app.dart';
import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:barcode_app/features/app_update/data/app_update_repository.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre a tela principal simplificada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(
            _SmokeReadingsRepository(),
          ),
          appUpdateFeatureEnabledProvider.overrideWithValue(true),
          appUpdateRepositoryProvider.overrideWithValue(
            _FailingAppUpdateRepository(),
          ),
        ],
        child: const BarcodeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
  });
}

class _FailingAppUpdateRepository implements AppUpdateRepository {
  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    throw Exception('manifest unavailable');
  }
}

class _SmokeReadingsRepository implements ReadingsRepository {
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
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {}

  @override
  Stream<List<ReadingItem>> watchActive() => const Stream.empty();

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
