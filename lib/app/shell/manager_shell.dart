import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _ManagerSidebar(
            currentPath: GoRouterState.of(context).matchedLocation,
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerSidebar extends StatelessWidget {
  const _ManagerSidebar({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Performaz',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.sidebarBorder, height: 1),
          const SizedBox(height: 8),

          // Nav items
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            path: '/manager',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.people_outlined,
            label: 'Vendedores',
            path: '/manager/sellers',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.store_outlined,
            label: 'Clientes',
            path: '/manager/clients',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Produtos',
            path: '/manager/products',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.route_outlined,
            label: 'Rotas',
            path: '/manager/routes',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.map_outlined,
            label: 'Mapa ao Vivo',
            path: '/manager/map',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.flag_outlined,
            label: 'Metas',
            path: '/manager/goals',
            currentPath: currentPath,
          ),
          _NavItem(
            icon: Icons.notifications_outlined,
            label: 'Notificações',
            path: '/manager/notifications',
            currentPath: currentPath,
          ),

          const Spacer(),
          const Divider(color: AppColors.sidebarBorder, height: 1),

          // Logout
          _NavItem(
            icon: Icons.logout,
            label: 'Sair',
            path: '/logout',
            currentPath: '',
            onTap: () => context.go('/login'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final VoidCallback? onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  bool get _isActive => widget.currentPath == widget.path;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () => context.go(widget.path),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isActive
                ? AppColors.sidebarAccent
                : _hovering
                    ? AppColors.sidebarAccent.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Active indicator — vertical red bar
              if (_isActive)
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
              Icon(
                widget.icon,
                size: 20,
                color: _isActive
                    ? Colors.white
                    : AppColors.sidebarForeground,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: _isActive
                      ? Colors.white
                      : AppColors.sidebarForeground,
                  fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
