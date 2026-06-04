import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_bloc.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/profile_screen.dart';
import '../features/gamification/achievements_screen.dart';
import '../features/gamification/gamification_dashboard.dart';
import '../features/gamification/leaderboard_screen.dart';
import '../features/gamification/quests_screen.dart';
import '../features/manager/manager_handoff_screen.dart';
import '../features/orders/cart_screen.dart';
import '../features/orders/no_sale_screen.dart';
import '../features/orders/product_catalog_screen.dart';
import '../features/routes/create_route_screen.dart';
import '../features/routes/navigate_to_client_screen.dart';
import '../features/routes/route_map_screen.dart';
import '../features/routes/checkin_screen.dart';
import '../features/routes/client_detail_screen.dart';
import '../features/routes/route_list_screen.dart';
import '../features/routes/route_cubit.dart';
import '../shared/models/route.dart' as models;
import 'role_home_route.dart';
import 'shell/seller_shell.dart';
import '../core/network/api_client.dart';
import '../core/repositories/crud_repository.dart';
import '../core/storage/secure_storage.dart';
import 'di.dart';

class AppRouter {
  AppRouter({required this.authBloc});

  final AuthBloc authBloc;

  late final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: _redirect,
    routes: [
      // --- Auth routes ---
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // --- Seller shell (mobile) ---
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CartCubit()),
            BlocProvider(
              create: (_) => ProductCatalogCubit(
                productSource: ApiProductSource(getIt<CrudRepository>()),
              )..loadProducts(),
            ),
            BlocProvider(
              create: (_) => RouteCubit(
                apiClient: getIt<ApiClient>(),
                secureStorage: getIt<SecureStorage>(),
              )..loadRoute(),
            ),
          ],
          child: SellerShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/routes/map',
            builder: (context, state) => const RouteMapScreen(),
          ),
          GoRoute(
            path: '/routes/create',
            builder: (context, state) => const CreateRouteScreen(),
          ),
          GoRoute(
            path: '/routes',
            builder: (context, state) => const RouteListScreen(),
          ),
          GoRoute(
            path: '/routes/:clientId',
            builder: (context, state) =>
                ClientDetailScreen(stop: state.extra! as models.RouteStop),
          ),
          GoRoute(
            path: '/routes/:clientId/checkin',
            builder: (context, state) =>
                CheckinScreen(stop: state.extra! as models.RouteStop),
          ),
          GoRoute(
            path: '/routes/:clientId/navigate',
            builder: (context, state) =>
                NavigateToClientScreen(stop: state.extra! as models.RouteStop),
          ),
          GoRoute(
            path: '/orders/catalog',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final clientId = extra?['clientId'] as String? ?? '';
              final clientName = extra?['clientName'] as String? ?? '';

              // Init cart with client info if provided
              if (clientId.isNotEmpty) {
                context.read<CartCubit>().initCart(
                  clientId: clientId,
                  clientName: clientName,
                );
              }

              // If no client in extras AND cart has no client, redirect
              final cartHasClient =
                  context.read<CartCubit>().state.clientId != null;
              if (clientId.isEmpty && !cartHasClient) {
                return const _NoClientCatalogFallback();
              }

              return ProductCatalogScreen(
                onProductSelected: (product) {
                  context.read<CartCubit>().addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} adicionado'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/orders/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders/no-sale',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return NoSaleScreen(
                clientId: extra?['clientId'] as String? ?? '',
                clientName: extra?['clientName'] as String? ?? '',
                routeId: extra?['routeId'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/gamification',
            builder: (context, state) => const GamificationDashboard(),
          ),
          GoRoute(
            path: '/gamification/quests',
            builder: (context, state) => const QuestsScreen(),
          ),
          GoRoute(
            path: '/gamification/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/gamification/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // --- Manager handoff ---
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerHandoffScreen(),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final isLoginRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/forgot-password';

    if (authState is AuthUnauthenticated && !isLoginRoute) {
      return '/login';
    }

    if (authState is AuthAuthenticated && isLoginRoute) {
      return homeRouteForRole(authState.user.role);
    }

    return null;
  }
}

// Helper to refresh GoRouter when AuthBloc state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Shown when the catalog is accessed without a client context.
class _NoClientCatalogFallback extends StatelessWidget {
  const _NoClientCatalogFallback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_outlined,
                  size: 64, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Selecione um cliente primeiro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesse a rota do dia e escolha um cliente para fazer um pedido.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/routes'),
                icon: const Icon(Icons.route, size: 18),
                label: const Text('Ir para Rota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
