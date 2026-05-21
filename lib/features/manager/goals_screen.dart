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
  });

  final String sellerId;
  final String sellerName;
  double revenueTarget;
  double revenueCurrent;
  int positivacaoTarget;
  int positivacaoCurrent;

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

  // ════════════════════════════════════════════════════════════════════
  // 🚧 MOCK — dados falsos para apresentação.
  //    Para integrar com a API real:
  //    1. Descomente a linha com repository.fetchGoals()
  //    2. Remova o Future.delayed e os dados mock
  //    3. Rode: flutter pub get && dart run build_runner build
  // ════════════════════════════════════════════════════════════════════
  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // TODO(api): final data = await repository.fetchGoals();

    final goals = [
      _SellerGoal(sellerId: 'v1', sellerName: 'Carlos Mendes', revenueTarget: 25000, revenueCurrent: 18200, positivacaoTarget: 30, positivacaoCurrent: 22),
      _SellerGoal(sellerId: 'v2', sellerName: 'Ana Rodrigues', revenueTarget: 25000, revenueCurrent: 21500, positivacaoTarget: 30, positivacaoCurrent: 28),
      _SellerGoal(sellerId: 'v3', sellerName: 'Usuário Teste', revenueTarget: 20000, revenueCurrent: 14800, positivacaoTarget: 25, positivacaoCurrent: 18),
      _SellerGoal(sellerId: 'v4', sellerName: 'Juliana Costa', revenueTarget: 22000, revenueCurrent: 16000, positivacaoTarget: 28, positivacaoCurrent: 20),
      _SellerGoal(sellerId: 'v5', sellerName: 'Roberto Alves', revenueTarget: 18000, revenueCurrent: 15500, positivacaoTarget: 20, positivacaoCurrent: 17),
    ];

    emit(state.copyWith(goals: goals, isLoading: false));
  }

  void setPeriod(GoalPeriod period) {
    emit(state.copyWith(period: period));
    load();
  }

  Future<void> updateRevenueTarget(String sellerId, double target) async {
    final goals = List<_SellerGoal>.from(state.goals);
    final idx = goals.indexWhere((g) => g.sellerId == sellerId);
    if (idx >= 0) {
      goals[idx].revenueTarget = target;
      emit(state.copyWith(goals: goals));
      // TODO(api): await repository.updateGoal(sellerId, {'revenueTarget': target});
    }
  }

  Future<void> updatePositivacaoTarget(String sellerId, int target) async {
    final goals = List<_SellerGoal>.from(state.goals);
    final idx = goals.indexWhere((g) => g.sellerId == sellerId);
    if (idx >= 0) {
      goals[idx].positivacaoTarget = target;
      emit(state.copyWith(goals: goals));
      // TODO(api): await repository.updateGoal(sellerId, {'positivacaoTarget': target});
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
