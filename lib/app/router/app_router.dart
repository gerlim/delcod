import 'package:barcode_app/features/inventory/presentation/inventory_home_page.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter({
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const InventoryHomePage(),
      ),
    ],
  );
}
