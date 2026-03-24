import 'package:barcode_app/features/auth/data/auth_repository.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, CurrentSession?>(AuthController.new);

class AuthController extends AsyncNotifier<CurrentSession?> {
  @override
  Future<CurrentSession?> build() {
    return ref.read(authRepositoryProvider).loadCurrentSession();
  }
}
