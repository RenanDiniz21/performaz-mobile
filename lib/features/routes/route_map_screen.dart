import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';
import 'route_cubit.dart';

class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Mapa da Rota', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: BlocBuilder<RouteCubit, RouteState>(
        builder: (context, state) {
          if (state is RouteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RouteError) {
            return Center(
              child: Text(state.message, style: AppTypography.body(14)),
            );
          }

          if (state is! RouteLoaded || state.stops.isEmpty) {
            final mutedFg = isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      size: 64, color: mutedFg.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Nenhuma visita hoje',
                      style: AppTypography.body(16).copyWith(color: mutedFg)),
                ],
              ),
            );
          }

          final stopsWithCoords = state.stops
              .where((s) =>
                  s.checkinLatitude != null && s.checkinLongitude != null)
              .toList();

          if (stopsWithCoords.isEmpty) {
            final mutedFg = isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight;
            final primaryColor = isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 64, color: mutedFg.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Clientes sem localização',
                      style: AppTypography.title(18).copyWith(color:
                          isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seus ${state.stops.length} clientes não possuem coordenadas cadastradas. Use a aba Rota para acessá-los.',
                      style: AppTypography.body(14).copyWith(color: mutedFg),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/routes'),
                      icon: const Icon(Icons.route, size: 18),
                      label: Text('Ir para Rota',
                          style: AppTypography.body(14, weight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _MapBody(stops: state.stops);
        },
      ),
    );
  }
}

class _MapBody extends StatefulWidget {
  const _MapBody({required this.stops});
  final List<RouteStop> stops;

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody> {
  final _mapController = MapController();
  int? _selectedIndex;
  LatLng? _vendorLocation;
  StreamSubscription<Position>? _locationSub;

  LatLng get _center {
    if (_vendorLocation != null) return _vendorLocation!;
    final withCoords = widget.stops.where(
        (s) => s.checkinLatitude != null && s.checkinLongitude != null);
    if (withCoords.isEmpty) return const LatLng(-23.5505, -46.6333);
    final first = withCoords.first;
    return LatLng(first.checkinLatitude!, first.checkinLongitude!);
  }

  LatLngBounds? get _bounds {
    final points = <LatLng>[
      ...widget.stops
          .where(
              (s) => s.checkinLatitude != null && s.checkinLongitude != null)
          .map((s) => LatLng(s.checkinLatitude!, s.checkinLongitude!)),
      ?_vendorLocation,
    ];
    if (points.length < 2) return null;
    return LatLngBounds.fromPoints(points);
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() =>
          _vendorLocation = LatLng(position.latitude, position.longitude));
      _fitBounds();

      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((pos) {
        if (mounted) {
          setState(
              () => _vendorLocation = LatLng(pos.latitude, pos.longitude));
        }
      });
    } catch (_) {}
  }

  void _fitBounds() {
    final bounds = _bounds;
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
          maxZoom: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14,
            onTap: (_, _) => setState(() => _selectedIndex = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.performaz.app',
            ),
            // Vendor location (blue pulsing dot)
            if (_vendorLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _vendorLocation!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            // Route line connecting stops in order
            if (_orderedCoords.length >= 2)
              PolylineLayer(
                polylines: <Polyline<Object>>[
                  Polyline(
                    points: _orderedCoords,
                    color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withValues(alpha: 0.5),
                    strokeWidth: 3,
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
            // Stop markers
            MarkerLayer(
              markers: widget.stops.indexed.map((entry) {
                final (index, stop) = entry;
                final coords = _stopCoords(stop);
                if (coords == null) return null;

                final isSelected = _selectedIndex == index;
                final statusColor = _colorForStatus(stop.status);

                return Marker(
                  point: coords,
                  width: isSelected ? 140 : 44,
                  height: isSelected ? 64 : 44,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              stop.clientName,
                              style: AppTypography.body(11,
                                      weight: FontWeight.w600)
                                  .copyWith(color: fgColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.body(12,
                                    weight: FontWeight.w700)
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).nonNulls.toList(),
            ),
          ],
        ),

        // Legend
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _LegendDot(AppColors.statusWarning, 'Pendente'),
                _LegendDot(AppColors.statusInfo, 'Visitado'),
                _LegendDot(AppColors.statusSuccess, 'Venda'),
                _LegendDot(AppColors.mutedForegroundDark, 'Sem venda'),
                _LegendDot(AppColors.inactiveGray, 'Pulado'),
              ],
            ),
          ),
        ),

        // My location button
        if (_vendorLocation != null)
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: cardColor,
              foregroundColor: Colors.blue,
              elevation: 2,
              onPressed: () {
                _mapController.move(_vendorLocation!, 15);
              },
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),

        // Selected stop detail card
        if (_selectedIndex != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _StopDetailCard(
              stop: widget.stops[_selectedIndex!],
              index: _selectedIndex!,
              onNavigate: () {
                final stop = widget.stops[_selectedIndex!];
                context.push('/routes/${stop.clientId}', extra: stop);
              },
            ),
          ),
      ],
    );
  }

  List<LatLng> get _orderedCoords {
    return widget.stops
        .where((s) => s.checkinLatitude != null && s.checkinLongitude != null)
        .map((s) => LatLng(s.checkinLatitude!, s.checkinLongitude!))
        .toList();
  }

  LatLng? _stopCoords(RouteStop stop) {
    if (stop.checkinLatitude != null && stop.checkinLongitude != null) {
      return LatLng(stop.checkinLatitude!, stop.checkinLongitude!);
    }
    return null;
  }

  Color _colorForStatus(VisitStatus status) {
    return switch (status) {
      VisitStatus.pendente => AppColors.statusWarning,
      VisitStatus.visitado => AppColors.statusInfo,
      VisitStatus.vendaRealizada => AppColors.statusSuccess,
      VisitStatus.visitaSemVenda => AppColors.mutedForegroundDark,
      VisitStatus.pulado => AppColors.inactiveGray,
    };
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.body(10, weight: FontWeight.w500)),
      ],
    );
  }
}

class _StopDetailCard extends StatelessWidget {
  const _StopDetailCard({
    required this.stop,
    required this.index,
    required this.onNavigate,
  });

  final RouteStop stop;
  final int index;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final statusColor = switch (stop.status) {
      VisitStatus.pendente => AppColors.statusWarning,
      VisitStatus.visitado => AppColors.statusInfo,
      VisitStatus.vendaRealizada => AppColors.statusSuccess,
      VisitStatus.visitaSemVenda => AppColors.mutedForegroundDark,
      VisitStatus.pulado => AppColors.inactiveGray,
    };
    final statusLabel = switch (stop.status) {
      VisitStatus.pendente => 'Pendente',
      VisitStatus.visitado => 'Visitado',
      VisitStatus.vendaRealizada => 'Concluído',
      VisitStatus.visitaSemVenda => 'Sem Venda',
      VisitStatus.pulado => 'Pulado',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${index + 1}',
              style: AppTypography.body(14, weight: FontWeight.w700)
                  .copyWith(color: statusColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stop.clientName,
                    style: AppTypography.title(15).copyWith(color: fgColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(statusLabel,
                          style: AppTypography.body(10,
                                  weight: FontWeight.w600)
                              .copyWith(color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stop.address,
                        style:
                            AppTypography.body(12).copyWith(color: mutedFg),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: Text('Ver',
                  style: AppTypography.body(13, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
