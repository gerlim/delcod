import 'package:barcode_app/legacy/features/auth/data/auth_repository.dart';
import 'package:barcode_app/legacy/features/auth/domain/current_session.dart';
import 'package:barcode_app/legacy/features/auth/domain/login_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, CurrentSession?>(AuthController.new);

class AuthController extends AsyncNotifier<CurrentSession?> {
  @override
  Future<CurrentSession?> build() {
    return ref.read(authRepositoryProvider).loadCurrentSession();
  }

  Future<void> signIn(LoginRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).signIn(request);
    });
  }

  void setActiveCompany(String? companyId) {
    final session = state.valueOrNull;
    if (session == null) {
      return;
    }

    state = AsyncData(session.withActiveCompany(companyId));
  }
}

