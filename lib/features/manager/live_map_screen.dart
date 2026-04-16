import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _SellerPosition {
  const _SellerPosition({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final DateTime updatedAt;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class LiveMapState {
  const LiveMapState({
    this.sellers = const [],
    this.isLoading = true,
    this.lastRefresh,
  });

  final List<_SellerPosition> sellers;
  final bool isLoading;
  final DateTime? lastRefresh;

  LiveMapState copyWith({
    List<_SellerPosition>? sellers,
    bool? isLoading,
    DateTime? lastRefresh,
  }) {
    return LiveMapState(
      sellers: sellers ?? this.sellers,
      isLoading: isLoading ?? this.isLoading,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class LiveMapCubit extends Cubit<LiveMapState> {
  LiveMapCubit() : super(const LiveMapState());

  Timer? _timer;

  Future<void> load() async {
    await _fetchPositions();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      _fetchPositions();
    });
  }

  Future<void> _fetchPositions() async {
    emit(state.copyWith(isLoading: state.sellers.isEmpty));
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // TODO: replace with real API
    final now = DateTime.now();
    final mock = [
      _SellerPosition(id: 's0', name: 'Carlos Silva', lat: -23.5505, lng: -46.6333, updatedAt: now),
      _SellerPosition(id: 's1', name: 'Ana Ferreira', lat: -23.5610, lng: -46.6250, updatedAt: now),
      _SellerPosition(id: 's2', name: 'Pedro Souza', lat: -23.5430, lng: -46.6400, updatedAt: now),
      _SellerPosition(id: 's3', name: 'Julia Lima', lat: -23.5550, lng: -46.6500, updatedAt: now),
      _SellerPosition(id: 's4', name: 'Rafael Costa', lat: -23.5480, lng: -46.6180, updatedAt: now),
    ];

    emit(state.copyWith(
      sellers: mock,
      isLoading: false,
      lastRefresh: now,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveMapCubit()..load(),
      child: const _LiveMapBody(),
    );
  }
}

class _LiveMapBody extends StatelessWidget {
  const _LiveMapBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveMapCubit, LiveMapState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              return Row(
                children: [
                  // Sidebar
                  SizedBox(
                    width: 300,
                    child: _SellerSidebar(
                      sellers: state.sellers,
                      lastRefresh: state.lastRefresh,
                    ),
                  ),
                  // Map
                  Expanded(
                    child: _MapView(sellers: state.sellers),
                  ),
                ],
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 200,
                  child: _SellerSidebar(
                    sellers: state.sellers,
                    lastRefresh: state.lastRefresh,
                  ),
                ),
                Expanded(
                  child: _MapView(sellers: state.sellers),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _SellerSidebar extends StatelessWidget {
  const _SellerSidebar({required this.sellers, required this.lastRefresh});

  final List<_SellerPosition> sellers;
  final DateTime? lastRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mapa ao Vivo',
                    style: AppTypography.displaySmall),
                const SizedBox(height: 8),
                _RefreshIndicator(lastRefresh: lastRefresh),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: sellers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final s = sellers[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.activeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: AppTypography.bodyMedium),
                            Text(
                              '${s.lat.toStringAsFixed(4)}, ${s.lng.toStringAsFixed(4)}',
                              style: AppTypography.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Refresh indicator
// ---------------------------------------------------------------------------

class _RefreshIndicator extends StatelessWidget {
  const _RefreshIndicator({required this.lastRefresh});
  final DateTime? lastRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.refresh, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 4),
        Text(
          'Atualização: a cada 2 min',
          style: AppTypography.label,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

class _MapView extends StatelessWidget {
  const _MapView({required this.sellers});
  final List<_SellerPosition> sellers;

  @override
  Widget build(BuildContext context) {
    final center = sellers.isNotEmpty
        ? LatLng(sellers.first.lat, sellers.first.lng)
        : const LatLng(-23.5505, -46.6333);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.performaz.app',
        ),
        MarkerLayer(
          markers: sellers.map((s) {
            return Marker(
              point: LatLng(s.lat, s.lng),
              width: 120,
              height: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sidebar,
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text(
                      s.name.split(' ').first,
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const Icon(Icons.location_on,
                      color: AppColors.primary, size: 24),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
