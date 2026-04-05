import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/boxes/box_list_screen.dart';
import '../screens/boxes/box_detail_screen.dart';
import '../screens/boxes/add_edit_box_screen.dart';
import '../screens/items/add_edit_item_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/generate/generate_qr_screen.dart';
import '../screens/search/search_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = RouterAuthNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // While loading, don't redirect
      if (isLoading) return null;

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/boxes',
            builder: (context, state) => const BoxListScreen(),
          ),
          GoRoute(
            path: '/boxes/:boxId',
            builder: (context, state) {
              final boxId = state.pathParameters['boxId']!;
              return BoxDetailScreen(boxId: boxId);
            },
          ),
          GoRoute(
            path: '/boxes/:boxId/edit',
            builder: (context, state) {
              final boxId = state.pathParameters['boxId']!;
              return AddEditBoxScreen(boxId: boxId);
            },
          ),
          GoRoute(
            path: '/add-box',
            builder: (context, state) => const AddEditBoxScreen(),
          ),
          GoRoute(
            path: '/boxes/:boxId/add-item',
            builder: (context, state) {
              final boxId = state.pathParameters['boxId']!;
              return AddEditItemScreen(boxId: boxId);
            },
          ),
          GoRoute(
            path: '/boxes/:boxId/items/:itemId/edit',
            builder: (context, state) {
              final boxId = state.pathParameters['boxId']!;
              final itemId = state.pathParameters['itemId']!;
              return AddEditItemScreen(boxId: boxId, itemId: itemId);
            },
          ),
          GoRoute(
            path: '/scan',
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: '/generate',
            builder: (context, state) => const GenerateQRScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Notifier that tells GoRouter to refresh when auth state changes
class RouterAuthNotifier extends ChangeNotifier {
  RouterAuthNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

/// Main shell widget with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/boxes')) return 1;
    if (location.startsWith('/scan') || location.startsWith('/add-box')) {
      return 2;
    }
    if (location.startsWith('/generate')) return 3;
    if (location.startsWith('/search')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/boxes');
              break;
            case 2:
              context.go('/scan');
              break;
            case 3:
              context.go('/generate');
              break;
            case 4:
              context.go('/search');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Boxes',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_outlined),
            selectedIcon: Icon(Icons.qr_code),
            label: 'Generate',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
