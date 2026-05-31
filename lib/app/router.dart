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
import '../features/manager/crud/clients_crud.dart';
import '../features/manager/crud/products_crud.dart';
import '../features/manager/crud/sellers_crud.dart';
import '../features/manager/dashboard_screen.dart';
import '../features/manager/goals_screen.dart';
import '../features/manager/live_map_screen.dart';
import '../features/manager/notifications_screen.dart';
import '../features/manager/routes_builder.dart';
import '../features/orders/cart_screen.dart';
import '../features/orders/no_sale_screen.dart';
import '../features/orders/order_summary_screen.dart';
import '../features/orders/product_catalog_screen.dart';
import '../features/routes/checkin_screen.dart';
import '../features/routes/client_detail_screen.dart';
import '../features/routes/route_list_screen.dart';
import '../features/routes/route_cubit.dart';
import '../shared/models/route.dart' as models;
import '../shared/models/user.dart';
import 'shell/seller_shell.dart';
import 'shell/manager_shell.dart';
import '../core/network/api_client.dart';
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // --- Seller shell (mobile) ---
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CartCubit()),
            BlocProvider(create: (_) => ProductCatalogCubit()),
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
            path: '/routes',
            builder: (context, state) => const RouteListScreen(),
          ),
          GoRoute(
            path: '/routes/:clientId',
            builder: (context, state) => ClientDetailScreen(
              stop: state.extra! as models.RouteStop,
            ),
          ),
          GoRoute(
            path: '/routes/:clientId/checkin',
            builder: (context, state) => CheckinScreen(
              stop: state.extra! as models.RouteStop,
            ),
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

              return ProductCatalogScreen(
                onProductSelected: (product) {
                  context.read<CartCubit>().addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} adicionado'),
                      duration: const Duration(seconds: 1),
                      action: SnackBarAction(
                        label: 'Ver Carrinho',
                        onPressed: () => context.push('/orders/cart'),
                      ),
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
            path: '/orders/summary',
            builder: (context, state) => const OrderSummaryScreen(),
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

      // --- Manager shell (web) ---
      ShellRoute(
        builder: (context, state, child) => ManagerShell(child: child),
        routes: [
          GoRoute(
            path: '/manager',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/manager/sellers',
            builder: (context, state) => const SellersCrudScreen(),
          ),
          GoRoute(
            path: '/manager/clients',
            builder: (context, state) => const ClientsCrudScreen(),
          ),
          GoRoute(
            path: '/manager/products',
            builder: (context, state) => const ProductsCrudScreen(),
          ),
          GoRoute(
            path: '/manager/routes',
            builder: (context, state) => const RoutesBuilderScreen(),
          ),
          GoRoute(
            path: '/manager/map',
            builder: (context, state) => const LiveMapScreen(),
          ),
          GoRoute(
            path: '/manager/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/manager/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final isLoginRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/forgot-password';

    if (authState is AuthUnauthenticated && !isLoginRoute) {
      return '/login';
    }

    if (authState is AuthAuthenticated && isLoginRoute) {
      return authState.user.role == UserRole.gestor ? '/manager' : '/routes';
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
