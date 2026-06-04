import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' as drift;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_database.dart';
import '../../shared/models/route.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';
import 'route_cubit.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum CheckinPhase { idle, locating, ready, submitting, success, error }

class CheckinState {
  const CheckinState({
    this.phase = CheckinPhase.idle,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.photoPath,
    this.errorMessage,
  });

  final CheckinPhase phase;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;
  final String? photoPath;
  final String? errorMessage;

  CheckinState copyWith({
    CheckinPhase? phase,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? photoPath,
    String? errorMessage,
  }) {
    return CheckinState(
      phase: phase ?? this.phase,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      photoPath: photoPath ?? this.photoPath,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class CheckinCubit extends Cubit<CheckinState> {
  CheckinCubit({required this.stop}) : super(const CheckinState());

  final RouteStop stop;
  final _picker = ImagePicker();

  Future<void> init() async {
    emit(state.copyWith(
      phase: CheckinPhase.locating,
      timestamp: DateTime.now(),
    ));

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          emit(state.copyWith(phase: CheckinPhase.ready));
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      emit(state.copyWith(
        phase: CheckinPhase.ready,
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      emit(state.copyWith(phase: CheckinPhase.ready));
    }
  }

  Future<void> pickPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (image != null) {
        emit(state.copyWith(photoPath: image.path));
      }
    } catch (_) {
      // User cancelled or camera unavailable
    }
  }

  Future<void> confirm() async {
    emit(state.copyWith(phase: CheckinPhase.submitting));
    try {
      final routeId = stop.routeId;
      if (routeId == null) {
        throw Exception('ID da rota não encontrado');
      }
      await getIt<ApiClient>().post('/routes/$routeId/checkin', data: {
        'clientId': stop.clientId,
        'lat': state.latitude,
        'lng': state.longitude,
        'photoUrl': state.photoPath,
      });
      emit(state.copyWith(phase: CheckinPhase.success));
    } catch (e) {
      try {
        await getIt<LocalDatabase>().insertCheckin(
          PendingCheckinsCompanion.insert(
            id: DateTime.now().toIso8601String(),
            routeId: drift.Value(stop.routeId),
            clientId: stop.clientId,
            checkinAt: state.timestamp ?? DateTime.now(),
            latitude: state.latitude ?? 0,
            longitude: state.longitude ?? 0,
            photoPath: drift.Value(state.photoPath),
          ),
        );
        emit(state.copyWith(phase: CheckinPhase.success));
      } catch (_) {
        emit(state.copyWith(
          phase: CheckinPhase.error,
          errorMessage: 'Erro ao registrar check-in: $e',
        ));
      }
    }
  }
}

enum CheckinOutcome { order, noSale }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CheckinScreen extends StatelessWidget {
  const CheckinScreen({super.key, required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckinCubit(stop: stop)..init(),
      child: const _CheckinView(),
    );
  }
}

class _CheckinView extends StatelessWidget {
  const _CheckinView();

  void _showOutcomeSheet(BuildContext context, RouteStop stop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    showModalBottomSheet<CheckinOutcome>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.statusSuccess, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Check-in realizado!',
                  style: AppTypography.title(20).copyWith(color: fgColor)),
              const SizedBox(height: 4),
              Text(stop.clientName,
                  style: AppTypography.body(14).copyWith(color: mutedFg)),
              const SizedBox(height: 24),
              Text('O que aconteceu na visita?',
                  style: AppTypography.body(14, weight: FontWeight.w500)
                      .copyWith(color: fgColor)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: Text('Fazer Pedido',
                      style: AppTypography.body(15, weight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/orders/catalog', extra: {
                      'clientId': stop.clientId,
                      'clientName': stop.clientName,
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.cancel_outlined,
                      size: 20, color: AppColors.statusWarning),
                  label: Text('Sem Venda',
                      style: AppTypography.body(15, weight: FontWeight.w600)
                          .copyWith(color: AppColors.statusWarning)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.statusWarning.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/orders/no-sale', extra: {
                      'clientId': stop.clientId,
                      'clientName': stop.clientName,
                      'routeId': stop.routeId,
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/routes');
                },
                child: Text('Voltar para rota',
                    style: AppTypography.body(14).copyWith(color: mutedFg)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Check-in', style: AppTypography.title(20)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fgColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: DotGridBackground(
        child: BlocConsumer<CheckinCubit, CheckinState>(
          listenWhen: (p, c) => c.phase == CheckinPhase.success,
          listener: (context, state) {
            final cubit = context.read<CheckinCubit>();
            context.read<RouteCubit>().markClientVisited(cubit.stop.clientId);
            _showOutcomeSheet(context, cubit.stop);
          },
          builder: (context, state) {
            final cubit = context.read<CheckinCubit>();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Client name
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente', style: AppTypography.body(12, weight: FontWeight.w500).copyWith(color: mutedFg)),
                      const SizedBox(height: 4),
                      Text(cubit.stop.clientName, style: AppTypography.title(18).copyWith(color: fgColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Timestamp
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: mutedFg),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Horário', style: AppTypography.body(12, weight: FontWeight.w500).copyWith(color: mutedFg)),
                          const SizedBox(height: 2),
                          Text(
                            state.timestamp != null
                                ? _formatTimestamp(state.timestamp!)
                                : '--',
                            style: AppTypography.body(14).copyWith(color: fgColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Geolocation
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        state.phase == CheckinPhase.locating
                            ? Icons.my_location
                            : state.latitude != null
                                ? Icons.location_on
                                : Icons.location_off_outlined,
                        size: 20,
                        color: state.phase == CheckinPhase.locating
                            ? mutedFg
                            : state.latitude != null
                                ? AppColors.statusSuccess
                                : mutedFg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Localização', style: AppTypography.body(12, weight: FontWeight.w500).copyWith(color: mutedFg)),
                            const SizedBox(height: 2),
                            if (state.phase == CheckinPhase.locating)
                              Text('Obtendo localização...',
                                  style: AppTypography.body(14).copyWith(color: mutedFg))
                            else if (state.latitude != null)
                              Text(
                                '${state.latitude!.toStringAsFixed(6)}, ${state.longitude!.toStringAsFixed(6)}',
                                style: AppTypography.body(14).copyWith(color: fgColor),
                              )
                            else
                              Text('Sem localização (opcional)',
                                  style: AppTypography.body(14).copyWith(color: mutedFg)),
                          ],
                        ),
                      ),
                      if (state.phase == CheckinPhase.locating)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Photo capture
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 20, color: mutedFg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Foto (opcional)', style: AppTypography.body(12, weight: FontWeight.w500).copyWith(color: mutedFg)),
                            const SizedBox(height: 2),
                            Text(
                              state.photoPath != null
                                  ? 'Foto capturada'
                                  : 'Nenhuma foto',
                              style: AppTypography.body(14).copyWith(
                                color: state.photoPath != null
                                    ? AppColors.statusSuccess
                                    : mutedFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: cubit.pickPhoto,
                        child: Text(
                          state.photoPath != null ? 'Trocar' : 'Capturar',
                          style: AppTypography.body(14, weight: FontWeight.w600).copyWith(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (state.phase == CheckinPhase.error &&
                    state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusError.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: AppTypography.body(13).copyWith(color: AppColors.statusError),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Confirm button
                if (state.phase != CheckinPhase.success) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (state.phase == CheckinPhase.ready)
                          ? cubit.confirm
                          : null,
                      child: state.phase == CheckinPhase.submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Confirmar Check-in',
                              style: AppTypography.body(15, weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}
