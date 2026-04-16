import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/widgets/filter_pills.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum LeaderboardPeriod { diario, semanal, mensal }

enum LeaderboardMetric { xp, faturamento }

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.rank,
    required this.xp,
    required this.revenue,
    this.isCurrentUser = false,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final int rank;
  final int xp;
  final double revenue;
  final bool isCurrentUser;

  @override
  List<Object?> get props =>
      [userId, name, photoUrl, rank, xp, revenue, isCurrentUser];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.period = LeaderboardPeriod.semanal,
    this.metric = LeaderboardMetric.xp,
    this.entries = const [],
    this.isLoading = true,
  });

  final LeaderboardPeriod period;
  final LeaderboardMetric metric;
  final List<LeaderboardEntry> entries;
  final bool isLoading;

  LeaderboardState copyWith({
    LeaderboardPeriod? period,
    LeaderboardMetric? metric,
    List<LeaderboardEntry>? entries,
    bool? isLoading,
  }) {
    return LeaderboardState(
      period: period ?? this.period,
      metric: metric ?? this.metric,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [period, metric, entries, isLoading];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit() : super(const LeaderboardState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));

    // TODO: replace with real repository call
    await Future<void>.delayed(const Duration(milliseconds: 500));

    emit(state.copyWith(
      isLoading: false,
      entries: const [
        LeaderboardEntry(
          userId: '1',
          name: 'Ana Souza',
          rank: 1,
          xp: 5820,
          revenue: 48500,
        ),
        LeaderboardEntry(
          userId: '2',
          name: 'Carlos Silva',
          rank: 2,
          xp: 4930,
          revenue: 42100,
          isCurrentUser: true,
        ),
        LeaderboardEntry(
          userId: '3',
          name: 'Marcos Lima',
          rank: 3,
          xp: 4210,
          revenue: 38900,
        ),
        LeaderboardEntry(
          userId: '4',
          name: 'Julia Santos',
          rank: 4,
          xp: 3890,
          revenue: 35200,
        ),
        LeaderboardEntry(
          userId: '5',
          name: 'Pedro Costa',
          rank: 5,
          xp: 3540,
          revenue: 31800,
        ),
        LeaderboardEntry(
          userId: '6',
          name: 'Fernanda Alves',
          rank: 6,
          xp: 3120,
          revenue: 28400,
        ),
        LeaderboardEntry(
          userId: '7',
          name: 'Roberto Dias',
          rank: 7,
          xp: 2870,
          revenue: 25100,
        ),
        LeaderboardEntry(
          userId: '8',
          name: 'Camila Rocha',
          rank: 8,
          xp: 2540,
          revenue: 22700,
        ),
      ],
    ));
  }

  void setPeriod(LeaderboardPeriod period) {
    emit(state.copyWith(period: period));
    load();
  }

  void setMetric(LeaderboardMetric metric) {
    emit(state.copyWith(metric: metric));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaderboardCubit()..load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Ranking', style: AppTypography.displaySmall),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return Column(
              children: [
                // Filters
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      FilterPills<LeaderboardPeriod>(
                        items: LeaderboardPeriod.values,
                        selected: state.period,
                        onSelected: (p) =>
                            context.read<LeaderboardCubit>().setPeriod(p),
                        labelBuilder: _periodLabel,
                      ),
                      const SizedBox(width: 12),
                      FilterPills<LeaderboardMetric>(
                        items: LeaderboardMetric.values,
                        selected: state.metric,
                        onSelected: (m) =>
                            context.read<LeaderboardCubit>().setMetric(m),
                        labelBuilder: _metricLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Podium
                if (state.entries.length >= 3)
                  _Podium(
                    first: state.entries[0],
                    second: state.entries[1],
                    third: state.entries[2],
                    metric: state.metric,
                  ),

                const SizedBox(height: 20),

                // Ranked list
                Expanded(
                  child: _RankedList(
                    entries: state.entries,
                    metric: state.metric,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _periodLabel(LeaderboardPeriod p) {
    return switch (p) {
      LeaderboardPeriod.diario => 'Diario',
      LeaderboardPeriod.semanal => 'Semanal',
      LeaderboardPeriod.mensal => 'Mensal',
    };
  }

  static String _metricLabel(LeaderboardMetric m) {
    return switch (m) {
      LeaderboardMetric.xp => 'XP',
      LeaderboardMetric.faturamento => 'Faturamento',
    };
  }
}

// ---------------------------------------------------------------------------
// Podium
// ---------------------------------------------------------------------------

class _Podium extends StatelessWidget {
  const _Podium({
    required this.first,
    required this.second,
    required this.third,
    required this.metric,
  });

  final LeaderboardEntry first;
  final LeaderboardEntry second;
  final LeaderboardEntry third;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _PodiumSlot(entry: second, metric: metric, height: 100)),
          const SizedBox(width: 10),
          // 1st place
          Expanded(child: _PodiumSlot(entry: first, metric: metric, height: 130)),
          const SizedBox(width: 10),
          // 3rd place
          Expanded(child: _PodiumSlot(entry: third, metric: metric, height: 80)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.metric,
    required this.height,
  });

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final double height;

  String get _initials {
    final parts = entry.name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  Color get _medalColor {
    return switch (entry.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.mutedForeground,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = entry.rank == 1;
    final avatarSize = isFirst ? 52.0 : 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: isFirst ? AppColors.primary : AppColors.muted,
              child: Text(
                _initials,
                style: AppTypography.bodyMedium.copyWith(
                  color: isFirst ? Colors.white : AppColors.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: isFirst ? 18 : 14,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          entry.name.split(' ').first,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Value
        Text(
          _formatValue(entry, metric),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        // Pedestal bar
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isFirst
                  ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]
                  : [AppColors.muted, AppColors.border],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ranked List
// ---------------------------------------------------------------------------

class _RankedList extends StatelessWidget {
  const _RankedList({
    required this.entries,
    required this.metric,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _RankedTile(entry: entry, metric: metric);
      },
    );
  }
}

class _RankedTile extends StatelessWidget {
  const _RankedTile({
    required this.entry,
    required this.metric,
  });

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  String get _initials {
    final parts = entry.name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accent : AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: entry.rank <= 3
                    ? AppColors.primary
                    : AppColors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: highlighted ? AppColors.primary : AppColors.muted,
            child: Text(
              _initials,
              style: AppTypography.bodySmall.copyWith(
                color: highlighted ? Colors.white : AppColors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (highlighted)
                  Text(
                    'Voce',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Value
          Text(
            _formatValue(entry, metric),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: highlighted ? AppColors.primary : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatValue(LeaderboardEntry entry, LeaderboardMetric metric) {
  return switch (metric) {
    LeaderboardMetric.xp => '${entry.xp} XP',
    LeaderboardMetric.faturamento =>
      'R\$ ${(entry.revenue / 1000).toStringAsFixed(1)}k',
  };
}
