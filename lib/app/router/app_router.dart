import 'package:barcode_app/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LoginPage(),
      ),
    ],
  );
}
