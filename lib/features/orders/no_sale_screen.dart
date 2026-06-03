import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../routes/route_cubit.dart';
import 'no_sale_submission.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NoSaleState extends Equatable {
  const NoSaleState({
    this.selectedReason,
    this.notes = '',
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.showValidationError = false,
    this.errorMessage,
  });

  final NoSaleReason? selectedReason;
  final String notes;
  final bool isSubmitting;
  final bool isSubmitted;
  final bool showValidationError;
  final String? errorMessage;

  bool get isValid => selectedReason != null;

  NoSaleState copyWith({
    NoSaleReason? selectedReason,
    String? notes,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? showValidationError,
    String? errorMessage,
  }) {
    return NoSaleState(
      selectedReason: selectedReason ?? this.selectedReason,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      showValidationError: showValidationError ?? this.showValidationError,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedReason,
    notes,
    isSubmitting,
    isSubmitted,
    showValidationError,
    errorMessage,
  ];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class NoSaleCubit extends Cubit<NoSaleState> {
  NoSaleCubit({required this.apiClient, required this.clientId, this.routeId})
    : super(const NoSaleState());

  final ApiClient apiClient;
  final String clientId;
  final String? routeId;

  void selectReason(NoSaleReason reason) {
    emit(state.copyWith(selectedReason: reason, showValidationError: false));
  }

  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  Future<void> submit() async {
    if (!state.isValid) {
      emit(state.copyWith(showValidationError: true));
      return;
    }

    emit(state.copyWith(isSubmitting: true));

    try {
      if (routeId == null || routeId!.isEmpty) {
        throw StateError('Rota nao encontrada para registrar visita sem venda');
      }

      await apiClient.post(
        buildNoSaleRoutePath(routeId!),
        data: buildNoSalePayload(
          clientId: clientId,
          reason: state.selectedReason!,
        ),
      );
      emit(state.copyWith(isSubmitting: false, isSubmitted: true));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          showValidationError: true,
          errorMessage: 'Erro ao registrar: $e',
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NoSaleScreen extends StatelessWidget {
  const NoSaleScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    this.routeId,
  });

  final String clientId;
  final String clientName;
  final String? routeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NoSaleCubit(
        apiClient: getIt<ApiClient>(),
        clientId: clientId,
        routeId: routeId,
      ),
      child: _NoSaleBody(clientId: clientId, clientName: clientName),
    );
  }
}

class _NoSaleBody extends StatelessWidget {
  const _NoSaleBody({required this.clientId, required this.clientName});

  final String clientId;
  final String clientName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Visita sem Venda', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: BlocConsumer<NoSaleCubit, NoSaleState>(
        listenWhen: (prev, curr) => !prev.isSubmitted && curr.isSubmitted,
        listener: (context, state) {
          final reason = state.selectedReason;
          if (reason != null) {
            context.read<RouteCubit>().markClientNoSale(
              clientId,
              reason.apiValue,
            );
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.statusSuccess,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text('Registrado', style: AppTypography.title(20)),
                ],
              ),
              content: Text(
                'Visita sem venda registrada.',
                style: AppTypography.body(14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/routes');
                  },
                  child: Text(
                    'OK',
                    style: AppTypography.body(14).copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Client header
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cliente',
                            style: AppTypography.body(
                              12,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(clientName, style: AppTypography.title(20)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reason label
                    Text(
                      'Motivo *',
                      style: AppTypography.body(
                        14,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // Reason radio buttons — using RadioGroup (Flutter 3.32+)
                    RadioGroup<NoSaleReason>(
                      groupValue: state.selectedReason,
                      onChanged: (v) {
                        if (v != null) {
                          context.read<NoSaleCubit>().selectReason(v);
                        }
                      },
                      child: Column(
                        children: NoSaleReason.values
                            .map(
                              (reason) => AppCard(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.zero,
                                child: RadioListTile<NoSaleReason>(
                                  value: reason,
                                  title: Text(
                                    reason.label,
                                    style: AppTypography.body(14),
                                  ),
                                  activeColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    // Validation error
                    if (state.showValidationError &&
                        state.selectedReason == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Selecione um motivo',
                          style: AppTypography.body(
                            13,
                          ).copyWith(color: AppColors.destructive),
                        ),
                      ),

                    // API error
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          state.errorMessage!,
                          style: AppTypography.body(
                            13,
                          ).copyWith(color: AppColors.destructive),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Notes
                    Text(
                      'Observações',
                      style: AppTypography.body(
                        14,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: context.read<NoSaleCubit>().updateNotes,
                      style: AppTypography.body(14),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Informações adicionais...',
                        hintStyle: AppTypography.body(14).copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Submit button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => context.read<NoSaleCubit>().submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryColor.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Registrar',
                              style: AppTypography.button.copyWith(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
