import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// Reasons
// ---------------------------------------------------------------------------

enum NoSaleReason {
  clienteClosed('Cliente fechado'),
  semInteresse('Sem interesse'),
  compraraDepois('Comprará depois');

  const NoSaleReason(this.label);
  final String label;
}

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
  });

  final NoSaleReason? selectedReason;
  final String notes;
  final bool isSubmitting;
  final bool isSubmitted;
  final bool showValidationError;

  bool get isValid => selectedReason != null;

  NoSaleState copyWith({
    NoSaleReason? selectedReason,
    String? notes,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? showValidationError,
  }) {
    return NoSaleState(
      selectedReason: selectedReason ?? this.selectedReason,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      showValidationError: showValidationError ?? this.showValidationError,
    );
  }

  @override
  List<Object?> get props =>
      [selectedReason, notes, isSubmitting, isSubmitted, showValidationError];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class NoSaleCubit extends Cubit<NoSaleState> {
  NoSaleCubit() : super(const NoSaleState());

  void selectReason(NoSaleReason reason) {
    emit(state.copyWith(
      selectedReason: reason,
      showValidationError: false,
    ));
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

    // TODO: persist via repository
    await Future.delayed(const Duration(milliseconds: 500));

    emit(state.copyWith(isSubmitting: false, isSubmitted: true));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NoSaleScreen extends StatelessWidget {
  const NoSaleScreen({
    super.key,
    required this.clientName,
  });

  final String clientName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NoSaleCubit(),
      child: _NoSaleBody(clientName: clientName),
    );
  }
}

class _NoSaleBody extends StatelessWidget {
  const _NoSaleBody({required this.clientName});

  final String clientName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text('Visita sem Venda', style: AppTypography.displaySmall),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<NoSaleCubit, NoSaleState>(
        listenWhen: (prev, curr) => !prev.isSubmitted && curr.isSubmitted,
        listener: (context, state) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              shape:
                  RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
              title: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 28),
                  const SizedBox(width: 12),
                  Text('Registrado', style: AppTypography.displaySmall),
                ],
              ),
              content: Text(
                'Visita sem venda registrada.',
                style: AppTypography.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/orders');
                  },
                  child: Text(
                    'OK',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente', style: AppTypography.label),
                          const SizedBox(height: 4),
                          Text(clientName,
                              style: AppTypography.displaySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reason label
                    Text(
                      'Motivo *',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // Reason radio buttons
                    ...NoSaleReason.values.map((reason) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: AppRadius.mdBorder,
                            border: Border.all(
                              color: state.selectedReason == reason
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: RadioListTile<NoSaleReason>(
                            value: reason,
                            groupValue: state.selectedReason,
                            onChanged: (v) {
                              if (v != null) {
                                context.read<NoSaleCubit>().selectReason(v);
                              }
                            },
                            title: Text(reason.label,
                                style: AppTypography.bodyMedium),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdBorder,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        )),

                    // Validation error
                    if (state.showValidationError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Selecione um motivo',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.destructive),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Notes
                    Text(
                      'Observações',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: context.read<NoSaleCubit>().updateNotes,
                      style: AppTypography.bodyMedium,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Informações adicionais...',
                        hintStyle: AppTypography.bodyMedium
                            .copyWith(color: AppColors.mutedForeground),
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorder,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorder,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorder,
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Submit button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.border)),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdBorder,
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
                          : Text('Registrar',
                              style: AppTypography.button
                                  .copyWith(fontSize: 16)),
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
