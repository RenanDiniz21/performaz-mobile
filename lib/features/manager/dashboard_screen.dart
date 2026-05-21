import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/repositories/manager_repository.dart';
import '../../shared/widgets/stat_card.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class _SellerRank {
  const _SellerRank(this.name, this.revenue);
  final String name;
  final double revenue;
}

class DashboardState {
  const DashboardState({
    this.activeSellers = 0,
    this.dailyRevenue = 0,
    this.teamGoalPercent = 0,
    this.ordersToday = 0,
    this.topSellers = const [],
    this.weeklyRevenue = const [],
    this.isLoading = true,
  });

  final int activeSellers;
  final double dailyRevenue;
  final double teamGoalPercent;
  final int ordersToday;
  final List<_SellerRank> topSellers;
  final List<double> weeklyRevenue;
  final bool isLoading;

  DashboardState copyWith({
    int? activeSellers,
    double? dailyRevenue,
    double? teamGoalPercent,
    int? ordersToday,
    List<_SellerRank>? topSellers,
    List<double>? weeklyRevenue,
    bool? isLoading,
  }) {
    return DashboardState(
      activeSellers: activeSellers ?? this.activeSellers,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      teamGoalPercent: teamGoalPercent ?? this.teamGoalPercent,
      ordersToday: ordersToday ?? this.ordersToday,
      topSellers: topSellers ?? this.topSellers,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required this.repository})
      : super(const DashboardState());

  final ManagerRepository repository;

  // ════════════════════════════════════════════════════════════════════
  // 🚧 MOCK — dados falsos para apresentação.
  //    Para integrar com a API real:
  //    1. Descomente as linhas com repository.fetchKpis() e fetchDailyRevenue()
  //    2. Remova o Future.delayed e os dados mock
  //    3. Rode: flutter pub get && dart run build_runner build
  // ════════════════════════════════════════════════════════════════════
  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // TODO(api): final kpis = await repository.fetchKpis();
    // TODO(api): final revenueData = await repository.fetchDailyRevenue(days: 7);

    emit(state.copyWith(
      activeSellers: 12,
      dailyRevenue: 18450.0,
      teamGoalPercent: 0.73,
      ordersToday: 28,
      topSellers: const [
        _SellerRank('Carlos Mendes', 5800),
        _SellerRank('Ana Rodrigues', 4500),
        _SellerRank('Usuário Teste', 4200),
        _SellerRank('Juliana Costa', 3800),
        _SellerRank('Roberto Alves', 3100),
      ],
      weeklyRevenue: const [12000, 15000, 11000, 18000, 16500, 19200, 18450],
      isLoading: false,
    ));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(
        repository: getIt<ManagerRepository>(),
      )..load(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Painel do Gestor', style: AppTypography.displayMedium),
                  const SizedBox(height: 24),

                  // KPI cards
                  _KpiRow(state: state, isWide: isWide),
                  const SizedBox(height: 24),

                  // Team goal progress
                  _TeamGoalBar(percent: state.teamGoalPercent),
                  const SizedBox(height: 24),

                  // Chart + Ranking
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _RevenueChart(data: state.weeklyRevenue),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _TopSellers(sellers: state.topSellers),
                        ),
                      ],
                    )
                  else ...[
                    _RevenueChart(data: state.weeklyRevenue),
                    const SizedBox(height: 24),
                    _TopSellers(sellers: state.topSellers),
                  ],
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
// KPI row
// ---------------------------------------------------------------------------

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.state, required this.isWide});
  final DashboardState state;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        label: 'Vendedores Ativos',
        value: '${state.activeSellers}',
        icon: Icons.people_outline,
        trend: '+2 esta semana',
      ),
      StatCard(
        label: 'Faturamento Diário',
        value: 'R\$ ${state.dailyRevenue.toStringAsFixed(0)}',
        icon: Icons.attach_money,
        trend: '+12% vs ontem',
      ),
      StatCard(
        label: 'Meta da Equipe',
        value: '${state.teamGoalPercent.toStringAsFixed(1)}%',
        icon: Icons.flag_outlined,
        trend: 'Faltam 26,5%',
        trendPositive: false,
      ),
      StatCard(
        label: 'Pedidos Hoje',
        value: '${state.ordersToday}',
        icon: Icons.shopping_cart_outlined,
        trend: '+5 vs ontem',
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                )))
            .toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(width: 280, child: c)).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Team goal bar
// ---------------------------------------------------------------------------

class _TeamGoalBar extends StatelessWidget {
  const _TeamGoalBar({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresso da Meta da Equipe',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('${percent.toStringAsFixed(1)}%',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.smBorder,
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 12,
              backgroundColor: AppColors.muted,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue chart
// ---------------------------------------------------------------------------

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Faturamento Semanal',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[idx], style: AppTypography.label);
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: data[i],
                      width: 24,
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top 5 sellers
// ---------------------------------------------------------------------------

class _TopSellers extends StatelessWidget {
  const _TopSellers({required this.sellers});
  final List<_SellerRank> sellers;

  @override
  Widget build(BuildContext context) {
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
          Text('Top 5 Vendedores',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...List.generate(sellers.length, (i) {
            final s = sellers[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i < 3 ? AppColors.accent : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            i < 3 ? AppColors.primary : AppColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.name, style: AppTypography.bodyMedium),
                  ),
                  Text(
                    'R\$ ${s.revenue.toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
