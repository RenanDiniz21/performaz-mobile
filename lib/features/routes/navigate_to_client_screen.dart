import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';

class NavigateToClientScreen extends StatefulWidget {
  const NavigateToClientScreen({super.key, required this.stop});

  final RouteStop stop;

  @override
  State<NavigateToClientScreen> createState() => _NavigateToClientScreenState();
}

class _NavigateToClientScreenState extends State<NavigateToClientScreen> {
  final _mapController = MapController();
  bool _loading = true;
  LatLng? _vendorLocation;
  List<LatLng> _routePoints = [];
  double? _distanceKm;
  int? _durationMinutes;
  String? _gpsWarning;

  LatLng? get _clientLocation {
    final lat = widget.stop.checkinLatitude;
    final lng = widget.stop.checkinLongitude;
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _gpsWarning = null;
    });

    // Try to get vendor GPS — non-blocking
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _gpsWarning = 'Localização não permitida — mostrando apenas o cliente';
      } else {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
        _vendorLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      _gpsWarning = 'GPS indisponível — mostrando apenas o cliente';
    }

    final client = _clientLocation;

    // If we have both, fetch route
    if (_vendorLocation != null && client != null) {
      await _fetchRoute(_vendorLocation!, client);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitView());
  }

  void _fitView() {
    final points = <LatLng>[
      ?_vendorLocation,
      ?_clientLocation,
    ];
    if (points.length >= 2) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(80),
          maxZoom: 16,
        ),
      );
    } else if (points.length == 1) {
      _mapController.move(points.first, 15);
    }
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';

      final response = await Dio().get(url);
      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List;

      if (routes.isEmpty) return;

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;
      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();

      final points = coords
          .map((c) => LatLng((c as List)[1].toDouble(), c[0].toDouble()))
          .toList();

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _distanceKm = distance / 1000;
        _durationMinutes = (duration / 60).ceil();
      });
    } catch (_) {
      // Route fetch failed — still show markers without polyline
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Navegação', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text('Calculando rota...',
                      style: AppTypography.body(14).copyWith(color: mutedFg)),
                ],
              ),
            )
          : Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _vendorLocation ?? const LatLng(-23.55, -46.63),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.performaz.app',
                        ),
                        // Route polyline
                        if (_routePoints.length >= 2)
                          PolylineLayer(
                            polylines: <Polyline<Object>>[
                              Polyline(
                                points: _routePoints,
                                color: primaryColor,
                                strokeWidth: 5,
                                borderColor:
                                    primaryColor.withValues(alpha: 0.3),
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        // Markers
                        MarkerLayer(
                          markers: [
                            // Vendor (blue dot)
                            if (_vendorLocation != null)
                              Marker(
                                point: _vendorLocation!,
                                width: 28,
                                height: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.blue.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Client (destination pin)
                            if (_clientLocation != null)
                              Marker(
                                point: _clientLocation!,
                                width: 120,
                                height: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.sm),
                                        border:
                                            Border.all(color: borderColor),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        widget.stop.clientName,
                                        style: AppTypography.body(10,
                                                weight: FontWeight.w600)
                                            .copyWith(color: fgColor),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Icon(Icons.location_on,
                                        color: AppColors.statusError,
                                        size: 28),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // GPS warning
                    if (_gpsWarning != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.statusWarning
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.statusWarning
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_off,
                                  size: 16,
                                  color: AppColors.statusWarning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _gpsWarning!,
                                  style: AppTypography.body(12,
                                          weight: FontWeight.w500)
                                      .copyWith(
                                          color: AppColors.statusWarning),
                                ),
                              ),
                              GestureDetector(
                                onTap: _init,
                                child: const Icon(Icons.refresh,
                                    size: 18,
                                    color: AppColors.statusWarning),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bottom info card
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          border: Border(top: BorderSide(color: borderColor)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        primaryColor.withValues(alpha: 0.15),
                                    child: Text(
                                      widget.stop.clientName[0].toUpperCase(),
                                      style: AppTypography.title(14)
                                          .copyWith(color: primaryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.stop.clientName,
                                            style: AppTypography.title(16)
                                                .copyWith(color: fgColor)),
                                        Text(widget.stop.address,
                                            style: AppTypography.body(12)
                                                .copyWith(color: mutedFg),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _InfoChip(
                                    icon: Icons.directions_car,
                                    label: _distanceKm != null
                                        ? '${_distanceKm!.toStringAsFixed(1)} km'
                                        : '–',
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoChip(
                                    icon: Icons.access_time,
                                    label: _durationMinutes != null
                                        ? '$_durationMinutes min'
                                        : '–',
                                    color: AppColors.statusSuccess,
                                  ),
                                  const Spacer(),
                                  FloatingActionButton.small(
                                    heroTag: 'recenter',
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    onPressed: () {
                                      if (_vendorLocation != null &&
                                          _clientLocation != null) {
                                        _mapController.fitCamera(
                                          CameraFit.bounds(
                                            bounds: LatLngBounds.fromPoints([
                                              _vendorLocation!,
                                              _clientLocation!,
                                            ]),
                                            padding: const EdgeInsets.all(80),
                                            maxZoom: 16,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Icon(Icons.zoom_out_map,
                                        size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.body(14, weight: FontWeight.w700)
                  .copyWith(color: color)),
        ],
      ),
    );
  }
}
