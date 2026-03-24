import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Barcode App'),
                SizedBox(height: 8),
                Text('Inicializando...'),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
