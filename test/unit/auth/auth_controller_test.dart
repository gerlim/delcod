import 'package:barcode_app/features/auth/application/auth_controller.dart';
import 'package:barcode_app/features/auth/data/auth_repository.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('inicia sem sessão autenticada', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(authControllerProvider.future);

    expect(session, isNull);
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super.forTest();

  @override
  Future<CurrentSession?> loadCurrentSession() async {
    return null;
  }
}
