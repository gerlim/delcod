import 'package:barcode_app/features/auth/application/auth_controller.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentSessionProvider = Provider<CurrentSession?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull;
});
