import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter({
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const ReadingsPage(),
      ),
    ],
  );
}
