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
    if (currentPath == '/routes/map') return 1;
    if (currentPath.startsWith('/routes')) return 0;
    if (currentPath.startsWith('/gamification')) return 2;
    if (currentPath.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    return NavigationBar(
      selectedIndex: _currentIndex,
      backgroundColor: AppColors.sidebarBg,
      indicatorColor: primaryColor.withValues(alpha: 0.2),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/routes');
          case 1:
            context.go('/routes/map');
          case 2:
            context.go('/gamification');
          case 3:
            context.go('/profile');
        }
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.route_outlined, color: inactiveColor),
          selectedIcon: Icon(Icons.route, color: primaryColor),
          label: 'Rota',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined, color: inactiveColor),
          selectedIcon: Icon(Icons.map, color: primaryColor),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined, color: inactiveColor),
          selectedIcon: Icon(Icons.emoji_events, color: primaryColor),
          label: 'Ranking',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: inactiveColor),
          selectedIcon: Icon(Icons.person, color: primaryColor),
          label: 'Perfil',
        ),
      ],
    );
  }
}
