import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/repositories/manager_repository.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum GoalPeriod { weekly, monthly }

class _SellerGoal {
  _SellerGoal({
    required this.sellerId,
    required this.sellerName,
    this.revenueTarget = 0,
    this.revenueCurrent = 0,
    this.positivacaoTarget = 0,
    this.positivacaoCurrent = 0,
    this.revenueGoalId,
    this.positivacaoGoalId,
  });

  final String sellerId;
  final String sellerName;
  double revenueTarget;
  double revenueCurrent;
  int positivacaoTarget;
  int positivacaoCurrent;
  String? revenueGoalId;
  String? positivacaoGoalId;

  double get revenuePercent =>
      revenueTarget > 0 ? (revenueCurrent / revenueTarget).clamp(0, 1) : 0;

  double get positivacaoPercent => positivacaoTarget > 0
      ? (positivacaoCurrent / positivacaoTarget).clamp(0, 1)
      : 0;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GoalsState {
  const GoalsState({
    this.goals = const [],
    this.period = GoalPeriod.monthly,
    this.isLoading = true,
  });

  final List<_SellerGoal> goals;
  final GoalPeriod period;
  final bool isLoading;

  GoalsState copyWith({
    List<_SellerGoal>? goals,
    GoalPeriod? period,
    bool? isLoading,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class GoalsCubit extends Cubit<GoalsState> {
  GoalsCubit({required this.repository}) : super(const GoalsState());

  final ManagerRepository repository;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final goalsData = await repository.fetchGoals();
      final vendorsData = await repository.fetchVendors();

      final apiPeriod = state.period == GoalPeriod.monthly ? 'mensal' : 'semanal';

      final List<_SellerGoal> sellerGoals = [];
      for (final vendor in vendorsData) {
        final vendorId = vendor['id'] as String;
        final vendorName = vendor['name'] as String;

        final vendorGoals = goalsData.where((g) =>
            g['vendorId'] == vendorId && g['period'] == apiPeriod);

        final revenueGoal = vendorGoals.firstWhere(
          (g) => g['type'] == 'receita',
          orElse: () => <String, dynamic>{},
        );

        final salesGoal = vendorGoals.firstWhere(
          (g) => g['type'] == 'vendas',
          orElse: () => <String, dynamic>{},
        );

        sellerGoals.add(_SellerGoal(
          sellerId: vendorId,
          sellerName: vendorName,
          revenueTarget: (revenueGoal['target'] as num? ?? 0).toDouble(),
          revenueCurrent: (revenueGoal['current'] as num? ?? 0).toDouble(),
          positivacaoTarget: (salesGoal['target'] as num? ?? 0).toInt(),
          positivacaoCurrent: (salesGoal['current'] as num? ?? 0).toInt(),
          revenueGoalId: revenueGoal['id'] as String?,
          positivacaoGoalId: salesGoal['id'] as String?,
        ));
      }

      emit(state.copyWith(goals: sellerGoals, isLoading: false));
    } catch (_) {
      emit(state.copyWith(goals: [], isLoading: false));
    }
  }

  void setPeriod(GoalPeriod period) {
    emit(state.copyWith(period: period));
    load();
  }

  Future<void> updateRevenueTarget(String sellerId, double target) async {
    final goals = List<_SellerGoal>.from(state.goals);
    final idx = goals.indexWhere((g) => g.sellerId == sellerId);
    if (idx >= 0) {
      final sellerGoal = goals[idx];
      sellerGoal.revenueTarget = target;
      emit(state.copyWith(goals: goals));
      try {
        if (sellerGoal.revenueGoalId != null) {
          await repository.updateGoal(sellerGoal.revenueGoalId!, {'target': target});
        } else {
          final now = DateTime.now();
          await repository.createGoal({
            'vendorId': sellerId,
            'period': state.period == GoalPeriod.monthly ? 'mensal' : 'semanal',
            'type': 'receita',
            'target': target,
            'startDate': DateTime(now.year, now.month, 1).toIso8601String(),
            'endDate': DateTime(now.year, now.month + 1, 0).toIso8601String(),
          });
          load();
        }
      } catch (_) {}
    }
  }

  Future<void> updatePositivacaoTarget(String sellerId, int target) async {
    final goals = List<_SellerGoal>.from(state.goals);
    final idx = goals.indexWhere((g) => g.sellerId == sellerId);
    if (idx >= 0) {
      final sellerGoal = goals[idx];
      sellerGoal.positivacaoTarget = target;
      emit(state.copyWith(goals: goals));
      try {
        if (sellerGoal.positivacaoGoalId != null) {
          await repository.updateGoal(sellerGoal.positivacaoGoalId!, {'target': target});
        } else {
          final now = DateTime.now();
          await repository.createGoal({
            'vendorId': sellerId,
            'period': state.period == GoalPeriod.monthly ? 'mensal' : 'semanal',
            'type': 'vendas',
            'target': target,
            'startDate': DateTime(now.year, now.month, 1).toIso8601String(),
            'endDate': DateTime(now.year, now.month + 1, 0).toIso8601String(),
          });
          load();
        }
      } catch (_) {}
    }
  }

  String formatCurrency(double value) => _currencyFormat.format(value);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GoalsCubit(
        repository: getIt<ManagerRepository>(),
      )..load(),
      child: const _GoalsBody(),
    );
  }
}

class _GoalsBody extends StatelessWidget {
  const _GoalsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header + period selector
                  Row(
                    children: [
                      Expanded(
                        child: Text('Metas',
                            style: AppTypography.displayMedium),
                      ),
                      _PeriodSelector(current: state.period),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Goal cards
                  ...state.goals.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _GoalCard(goal: g),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Period selector
// ---------------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.current});
  final GoalPeriod current;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<GoalPeriod>(
      segments: const [
        ButtonSegment(value: GoalPeriod.weekly, label: Text('Semanal')),
        ButtonSegment(value: GoalPeriod.monthly, label: Text('Mensal')),
      ],
      selected: {current},
      onSelectionChanged: (s) =>
          context.read<GoalsCubit>().setPeriod(s.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.card;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.foreground;
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal card per seller
// ---------------------------------------------------------------------------

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final _SellerGoal goal;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GoalsCubit>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller name + edit targets
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  goal.sellerName[0],
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(goal.sellerName,
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.mutedForeground,
                onPressed: () => _showEditDialog(context, goal),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Revenue progress
          _ProgressRow(
            label: 'Faturamento',
            current: cubit.formatCurrency(goal.revenueCurrent),
            target: cubit.formatCurrency(goal.revenueTarget),
            percent: goal.revenuePercent,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Positivacao progress
          _ProgressRow(
            label: 'Positivação',
            current: '${goal.positivacaoCurrent} vendas',
            target: '${goal.positivacaoTarget} vendas',
            percent: goal.positivacaoPercent,
            color: AppColors.chart3,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, _SellerGoal goal) {
    final revenueCtrl =
        TextEditingController(text: goal.revenueTarget.toStringAsFixed(0));
    final posCtrl =
        TextEditingController(text: goal.positivacaoTarget.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Meta — ${goal.sellerName}',
            style: AppTypography.displaySmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: revenueCtrl,
              decoration:
                  const InputDecoration(labelText: 'Meta de Faturamento (R\$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: posCtrl,
              decoration: const InputDecoration(
                  labelText: 'Meta de Positivação (vendas)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final rev = double.tryParse(revenueCtrl.text);
              final pos = int.tryParse(posCtrl.text);
              if (rev != null) {
                context
                    .read<GoalsCubit>()
                    .updateRevenueTarget(goal.sellerId, rev);
              }
              if (pos != null) {
                context
                    .read<GoalsCubit>()
                    .updatePositivacaoTarget(goal.sellerId, pos);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress row
// ---------------------------------------------------------------------------

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.percent,
    required this.color,
  });

  final String label;
  final String current;
  final String target;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.label),
            Text(
              '$current / $target',
              style: AppTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.smBorder,
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: AppColors.muted,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
