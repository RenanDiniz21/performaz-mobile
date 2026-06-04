import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/repositories/gamification_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class SellerQuest extends Equatable {
  const SellerQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.icon,
    required this.target,
    required this.xpReward,
    required this.current,
    required this.completed,
    this.endDate,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String category;
  final String icon;
  final double target;
  final int xpReward;
  final double current;
  final bool completed;
  final DateTime? endDate;

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;

  @override
  List<Object?> get props => [id, current, completed];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class QuestsState extends Equatable {
  const QuestsState({
    this.quests = const [],
    this.isLoading = true,
    this.error,
    this.filter = 'todas',
  });

  final List<SellerQuest> quests;
  final bool isLoading;
  final String? error;
  final String filter;

  List<SellerQuest> get filtered {
    if (filter == 'todas') return quests;
    if (filter == 'ativas') return quests.where((q) => !q.completed).toList();
    if (filter == 'concluidas') return quests.where((q) => q.completed).toList();
    return quests.where((q) => q.type == filter).toList();
  }

  QuestsState copyWith({
    List<SellerQuest>? quests,
    bool? isLoading,
    String? error,
    String? filter,
  }) {
    return QuestsState(
      quests: quests ?? this.quests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [quests, isLoading, error, filter];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class QuestsCubit extends Cubit<QuestsState> {
  QuestsCubit({required this.repository}) : super(const QuestsState());

  final GamificationRepository repository;

  Future<void> load(String vendorId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final rows = await repository.fetchQuests();
      final quests = rows.map((q) {
        final progressList = q['progress'] as List? ?? [];
        final vendorProgress = progressList
            .whereType<Map<String, dynamic>>()
            .where((p) =>
                p['vendorId'] == vendorId || p['vendor_id'] == vendorId)
            .toList();

        final current =
            vendorProgress.isNotEmpty
                ? (vendorProgress.first['current'] as num?)?.toDouble() ?? 0.0
                : 0.0;
        final completed =
            vendorProgress.isNotEmpty
                ? (vendorProgress.first['completed'] as bool?) ?? false
                : false;

        return SellerQuest(
          id: q['id'] as String,
          title: q['title'] as String,
          description: q['description'] as String,
          type: q['type'] as String? ?? '',
          category: q['category'] as String? ?? '',
          icon: q['icon'] as String? ?? '🎯',
          target: (q['target'] as num).toDouble(),
          xpReward: q['xpReward'] as int? ?? q['xp_reward'] as int? ?? 0,
          current: current,
          completed: completed,
          endDate: q['endDate'] != null
              ? DateTime.tryParse(q['endDate'].toString())
              : q['end_date'] != null
                  ? DateTime.tryParse(q['end_date'].toString())
                  : null,
        );
      }).toList();

      emit(state.copyWith(quests: quests, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(filter: filter));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final vendorId =
        authState is AuthAuthenticated ? authState.user.id : 'current';

    return BlocProvider(
      create: (_) => QuestsCubit(
        repository: getIt<GamificationRepository>(),
      )..load(vendorId),
      child: _QuestsBody(vendorId: vendorId),
    );
  }
}

class _QuestsBody extends StatelessWidget {
  const _QuestsBody({required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Missões', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: DotGridBackground(
        child: BlocBuilder<QuestsCubit, QuestsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }

            if (state.error != null && state.quests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.statusError),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar missões',
                        style: AppTypography.body(14).copyWith(color: mutedFg)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<QuestsCubit>().load(vendorId),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            final filtered = state.filtered;
            final completedCount =
                state.quests.where((q) => q.completed).length;

            return Column(
              children: [
                // Summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        '$completedCount/${state.quests.length} concluídas',
                        style: AppTypography.body(14, weight: FontWeight.w600)
                            .copyWith(color: primaryColor),
                      ),
                      const Spacer(),
                      Text(
                        '${state.quests.fold<int>(0, (s, q) => s + (q.completed ? q.xpReward : 0))} XP ganho',
                        style: AppTypography.body(13)
                            .copyWith(color: AppColors.xpGold),
                      ),
                    ],
                  ),
                ),

                // Filter chips
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: [
                      _FilterChip('Todas', 'todas', state.filter,
                          (v) => context.read<QuestsCubit>().setFilter(v)),
                      const SizedBox(width: 8),
                      _FilterChip('Ativas', 'ativas', state.filter,
                          (v) => context.read<QuestsCubit>().setFilter(v)),
                      const SizedBox(width: 8),
                      _FilterChip('Concluídas', 'concluidas', state.filter,
                          (v) => context.read<QuestsCubit>().setFilter(v)),
                      const SizedBox(width: 8),
                      _FilterChip('Diárias', 'diaria', state.filter,
                          (v) => context.read<QuestsCubit>().setFilter(v)),
                      const SizedBox(width: 8),
                      _FilterChip('Semanais', 'semanal', state.filter,
                          (v) => context.read<QuestsCubit>().setFilter(v)),
                    ],
                  ),
                ),

                // Quest list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('Nenhuma missão encontrada',
                              style: AppTypography.body(14)
                                  .copyWith(color: mutedFg)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _QuestTile(quest: filtered[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, this.value, this.current, this.onSelected);

  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final isActive = current == value;

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: AppTypography.body(13, weight: FontWeight.w500).copyWith(
        color: isActive ? primaryColor : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quest tile
// ---------------------------------------------------------------------------

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest});
  final SellerQuest quest;

  String _typeLabel(String type) {
    return switch (type) {
      'diaria' => 'Diária',
      'semanal' => 'Semanal',
      'unica' => 'Única',
      _ => type,
    };
  }

  String _categoryLabel(String cat) {
    return switch (cat) {
      'visitas' => 'Visitas',
      'vendas' => 'Vendas',
      'receita' => 'Receita',
      'reativacao' => 'Reativação',
      'produto' => 'Produto',
      'especial' => 'Especial',
      _ => cat,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final progressColor =
        quest.completed ? AppColors.statusSuccess : primaryColor;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(quest.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title,
                        style: AppTypography.body(15, weight: FontWeight.w600)
                            .copyWith(
                              color: fgColor,
                              decoration: quest.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                    const SizedBox(height: 2),
                    Text(quest.description,
                        style:
                            AppTypography.body(12).copyWith(color: mutedFg),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '+${quest.xpReward} XP',
                  style: AppTypography.body(11, weight: FontWeight.w700)
                      .copyWith(color: AppColors.xpGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: quest.progress,
                    minHeight: 6,
                    backgroundColor: progressColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                quest.completed
                    ? 'Concluída'
                    : '${quest.current.toInt()} / ${quest.target.toInt()}',
                style: AppTypography.body(12, weight: FontWeight.w600)
                    .copyWith(color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tags
          Wrap(
            spacing: 6,
            children: [
              _Tag(_typeLabel(quest.type), primaryColor),
              _Tag(_categoryLabel(quest.category), mutedFg),
              if (quest.completed)
                _Tag('Concluída', AppColors.statusSuccess),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.body(10, weight: FontWeight.w600)
              .copyWith(color: color)),
    );
  }
}
