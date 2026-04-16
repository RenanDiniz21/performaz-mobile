import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';

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
          emit(state.copyWith(
            phase: CheckinPhase.error,
            errorMessage: 'Permissão de localização negada',
          ));
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
      emit(state.copyWith(
        phase: CheckinPhase.error,
        errorMessage: 'Erro ao obter localização: $e',
      ));
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
      // TODO: persist check-in via repository
      await Future<void>.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(phase: CheckinPhase.success));
    } catch (e) {
      emit(state.copyWith(
        phase: CheckinPhase.error,
        errorMessage: 'Erro ao registrar check-in: $e',
      ));
    }
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text('Check-in', style: AppTypography.displaySmall),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocConsumer<CheckinCubit, CheckinState>(
        listenWhen: (p, c) => c.phase == CheckinPhase.success,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                'Check-in realizado com sucesso!',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) context.pop(true);
          });
        },
        builder: (context, state) {
          final cubit = context.read<CheckinCubit>();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Client name
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cliente', style: AppTypography.label),
                    const SizedBox(height: 4),
                    Text(cubit.stop.clientName,
                        style: AppTypography.displayMedium),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Timestamp
              _Card(
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 20, color: AppColors.mutedForeground),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Horário', style: AppTypography.label),
                        const SizedBox(height: 2),
                        Text(
                          state.timestamp != null
                              ? _formatTimestamp(state.timestamp!)
                              : '--',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Geolocation
              _Card(
                child: Row(
                  children: [
                    Icon(
                      state.phase == CheckinPhase.locating
                          ? Icons.my_location
                          : Icons.location_on,
                      size: 20,
                      color: state.phase == CheckinPhase.locating
                          ? AppColors.mutedForeground
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Localização', style: AppTypography.label),
                          const SizedBox(height: 2),
                          if (state.phase == CheckinPhase.locating)
                            Text('Obtendo localização...',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.mutedForeground))
                          else if (state.latitude != null)
                            Text(
                              '${state.latitude!.toStringAsFixed(6)}, ${state.longitude!.toStringAsFixed(6)}',
                              style: AppTypography.bodyMedium,
                            )
                          else
                            Text('Indisponível',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.destructive)),
                        ],
                      ),
                    ),
                    if (state.phase == CheckinPhase.locating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Photo capture
              _Card(
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 20, color: AppColors.mutedForeground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Foto (opcional)', style: AppTypography.label),
                          const SizedBox(height: 2),
                          Text(
                            state.photoPath != null
                                ? 'Foto capturada'
                                : 'Nenhuma foto',
                            style: AppTypography.bodyMedium.copyWith(
                              color: state.photoPath != null
                                  ? AppColors.success
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: cubit.pickPhoto,
                      child: Text(
                        state.photoPath != null ? 'Trocar' : 'Capturar',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
                    color: AppColors.highBg,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.highFg),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Success feedback
              if (state.phase == CheckinPhase.success)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: AppRadius.lgBorder,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Check-in realizado!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Confirm button
              if (state.phase != CheckinPhase.success) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.lgBorder),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.muted,
                    ),
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
                        : Text(
                            'Confirmar Check-in',
                            style: AppTypography.button,
                          ),
                  ),
                ),
              ],
            ],
          );
        },
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

// ---------------------------------------------------------------------------
// Shared card wrapper
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
