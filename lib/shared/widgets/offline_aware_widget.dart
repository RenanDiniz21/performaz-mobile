import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/sync/sync_service.dart';

class OfflineAwareWidget extends StatelessWidget {
  const OfflineAwareWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final connectivity = getIt<ConnectivityService>();
    final syncService = getIt<SyncService>();

    return Stack(
      children: [
        // Main content with offline banner on top
        Column(
          children: [
            StreamBuilder<bool>(
              stream: connectivity.onConnectivityChanged,
              initialData: connectivity.isOnline,
              builder: (context, snapshot) {
                final isOnline = snapshot.data ?? true;
                if (isOnline) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: AppColors.mediumBg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 16, color: AppColors.mediumFg),
                      const SizedBox(width: 8),
                      Text(
                        'Sem conexão — dados serão sincronizados',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.mediumFg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(child: child),
          ],
        ),
        // Floating sync pill — always accessible
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: _SyncPill(syncService: syncService),
        ),
      ],
    );
  }
}

class _SyncPill extends StatefulWidget {
  const _SyncPill({required this.syncService});
  final SyncService syncService;

  @override
  State<_SyncPill> createState() => _SyncPillState();
}

class _SyncPillState extends State<_SyncPill> {
  int _pendingCount = 0;
  SyncStatus? _lastStatus;
  StreamSubscription<SyncStatus>? _sub;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
    _sub = widget.syncService.syncStatus.listen(_onSyncStatus);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    final count = await widget.syncService.getPendingCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  void _onSyncStatus(SyncStatus status) {
    if (!mounted) return;
    setState(() => _lastStatus = status);
    if (status == SyncStatus.synced) {
      _loadPendingCount();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _lastStatus = null);
      });
    } else if (status == SyncStatus.error) {
      _loadPendingCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = _lastStatus == SyncStatus.syncing ||
        _lastStatus == SyncStatus.synced ||
        _lastStatus == SyncStatus.error ||
        _pendingCount > 0;

    if (!show) return const SizedBox.shrink();

    final (icon, label, color) = switch (_lastStatus) {
      SyncStatus.syncing => (
          null as IconData?,
          'Sincronizando...',
          AppColors.statusInfo,
        ),
      SyncStatus.synced => (
          Icons.check_circle,
          'Sincronizado',
          AppColors.statusSuccess,
        ),
      SyncStatus.error => (
          Icons.sync_problem,
          '$_pendingCount pendente(s) — toque para tentar',
          AppColors.statusError,
        ),
      null => (
          Icons.cloud_upload_outlined,
          '$_pendingCount pendente(s) — toque para sincronizar',
          AppColors.statusWarning,
        ),
    };

    return Center(
      child: GestureDetector(
        onTap: _lastStatus != SyncStatus.syncing
            ? () => widget.syncService.syncAll()
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lastStatus == SyncStatus.syncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.body(13, weight: FontWeight.w600)
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
