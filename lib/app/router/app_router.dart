import 'package:barcode_app/app/shell/app_shell.dart';
import 'package:barcode_app/features/admin/presentation/admin_users_page.dart';
import 'package:barcode_app/features/audit/presentation/audit_page.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/presentation/login_page.dart';
import 'package:barcode_app/features/collections/application/collections_controller.dart';
import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:barcode_app/features/collections/presentation/collections_page.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter({
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const _SessionLandingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _AuthenticatedShellRoute(
            currentLocation: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/collections',
            builder: (_, __) => const CollectionsPage(),
          ),
          GoRoute(
            path: '/collections/:collectionId',
            builder: (context, state) {
              final extraCollection = state.extra;
              if (extraCollection is CollectionItem) {
                return ReadingsPage(
                  collectionId: extraCollection.id,
                  collectionTitle: extraCollection.title,
                );
              }

              return _CollectionRoutePage(
                collectionId: state.pathParameters['collectionId']!,
              );
            },
          ),
          GoRoute(
            path: '/audit',
            builder: (_, __) => const _RoleGate(
                  allowedRoles: {'manager', 'admin'},
                  child: AuditPage(),
                ),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const _RoleGate(
                  allowedRoles: {'admin'},
                  child: AdminUsersPage(),
                ),
          ),
        ],
      ),
    ],
  );
}

class _SessionLandingPage extends ConsumerWidget {
  const _SessionLandingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);

    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/collections');
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const LoginPage();
  }
}

class _AuthenticatedShellRoute extends ConsumerWidget {
  const _AuthenticatedShellRoute({
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      return const LoginPage();
    }

    return AppShell(
      currentLocation: currentLocation,
      child: child,
    );
  }
}

class _RoleGate extends ConsumerWidget {
  const _RoleGate({
    required this.allowedRoles,
    required this.child,
  });

  final Set<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(currentSessionProvider)?.roles ?? const <String>{};
    final authorized = roles.any(allowedRoles.contains);

    if (authorized) {
      return child;
    }

    return const _AccessDeniedPage();
  }
}

class _CollectionRoutePage extends ConsumerWidget {
  const _CollectionRoutePage({
    required this.collectionId,
  });

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionItemProvider(collectionId));

    return collection.when(
      data: (item) {
        if (item == null) {
          return const _AccessDeniedPage(
            title: 'Coleta nao encontrada',
            message: 'Essa coleta nao esta disponivel neste dispositivo.',
          );
        }

        return ReadingsPage(
          collectionId: item.id,
          collectionTitle: item.title,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const _AccessDeniedPage(
        title: 'Falha ao carregar coleta',
        message: 'Tente novamente em instantes.',
      ),
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({
    this.title = 'Acesso negado',
    this.message =
        'Seu perfil atual nao possui permissao para acessar este modulo.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
