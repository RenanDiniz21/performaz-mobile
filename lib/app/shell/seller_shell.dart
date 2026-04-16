import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../shared/widgets/dot_grid_background.dart';
import '../../shared/widgets/offline_aware_widget.dart';

class SellerShell extends StatelessWidget {
  const SellerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineAwareWidget(
        child: DotGridBackground(child: child),
      ),
      bottomNavigationBar: _SellerBottomNav(
        currentPath: GoRouterState.of(context).matchedLocation,
      ),
    );
  }
}

class _SellerBottomNav extends StatelessWidget {
  const _SellerBottomNav({required this.currentPath});

  final String currentPath;

  int get _currentIndex {
    if (currentPath.startsWith('/routes')) return 0;
    if (currentPath.startsWith('/orders')) return 1;
    if (currentPath.startsWith('/gamification')) return 2;
    if (currentPath.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: _currentIndex,
      backgroundColor: cs.surface,
      indicatorColor: cs.primary.withValues(alpha: 0.12),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/routes');
          case 1:
            context.go('/orders/catalog');
          case 2:
            context.go('/gamification');
          case 3:
            context.go('/profile');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route, color: cs.primary),
          label: 'Rota',
        ),
        NavigationDestination(
          icon: const Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart, color: cs.primary),
          label: 'Pedidos',
        ),
        NavigationDestination(
          icon: const Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events, color: cs.primary),
          label: 'Ranking',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: cs.primary),
          label: 'Perfil',
        ),
      ],
    );
  }
}
