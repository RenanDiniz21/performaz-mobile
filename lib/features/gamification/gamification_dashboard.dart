import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/repositories/gamification_repository.dart';
import '../../shared/models/achievement.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/stat_card.dart';
import 'seller_goal_progress.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GamificationDashboardState extends Equatable {
  const GamificationDashboardState({
    this.user,
    this.error,
    this.currentXp = 0,
    this.nextLevelXp = 1000,
    this.dailyScore = 0,
    this.weeklyScore = 0,
    this.dailyTrend,
    this.weeklyTrend,
    this.goals = const [],
    this.nextAchievements = const [],
    this.recentXpEvents = const [],
    this.isLoading = true,
  });

  final User? user;
  final int currentXp;
  final int nextLevelXp;
  final int dailyScore;
  final int weeklyScore;
  final String? dailyTrend;
  final String? weeklyTrend;
  final List<SellerGoalProgress> goals;
  final List<Achievement> nextAchievements;
  final List<XpEvent> recentXpEvents;
  final bool isLoading;
  final String? error;

  double get xpProgress =>
      nextLevelXp > 0 ? (currentXp / nextLevelXp).clamp(0.0, 1.0) : 0;

  GamificationDashboardState copyWith({
    User? user,
    int? currentXp,
    int? nextLevelXp,
    int? dailyScore,
    int? weeklyScore,
    String? dailyTrend,
    String? weeklyTrend,
    List<SellerGoalProgress>? goals,
    List<Achievement>? nextAchievements,
    List<XpEvent>? recentXpEvents,
    bool? isLoading,
    String? error,
  }) {
    return GamificationDashboardState(
      user: user ?? this.user,
      currentXp: currentXp ?? this.currentXp,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      dailyScore: dailyScore ?? this.dailyScore,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      dailyTrend: dailyTrend ?? this.dailyTrend,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      goals: goals ?? this.goals,
      nextAchievements: nextAchievements ?? this.nextAchievements,
      recentXpEvents: recentXpEvents ?? this.recentXpEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        user,
        currentXp,
        nextLevelXp,
        dailyScore,
        weeklyScore,
        dailyTrend,
        weeklyTrend,
        goals,
        nextAchievements,
        recentXpEvents,
        isLoading,
        error,
      ];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class GamificationDashboardCubit extends Cubit<GamificationDashboardState> {
  GamificationDashboardCubit({required this.repository})
      : super(const GamificationDashboardState());

  final GamificationRepository repository;

  Future<void> load(String vendorId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await Future.wait([
        repository.fetchVendorStats(vendorId),
        repository.fetchVendorGoals(vendorId),
      ]);
      final stats = results[0] as Map<String, dynamic>;
      final goals = sellerGoalsFromApi(results[1] as List<dynamic>);

      final vendor = stats['vendor'] as Map<String, dynamic>;
      final xp = vendor['xp'] as int? ?? 0;
      final level = vendor['level'] as int? ?? 1;

      final achievementsList = stats['achievements'] as List? ?? [];
      final achievements = achievementsList
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();

      final xpList = stats['xpHistory'] as List? ?? [];
      final xpEvents = xpList
          .map((e) => XpEvent.fromJson(e as Map<String, dynamic>))
          .toList();

      final nextLevelXp = level * 1000;
      final currentLevelXpProgress = xp % nextLevelXp;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dailyScore = xpEvents
          .where((e) => e.createdAt.isAfter(today))
          .fold(0, (sum, e) => sum + e.xpAmount);

      final weekAgo = today.subtract(const Duration(days: 7));
      final weeklyScore = xpEvents
          .where((e) => e.createdAt.isAfter(weekAgo))
          .fold(0, (sum, e) => sum + e.xpAmount);

      emit(state.copyWith(
        isLoading: false,
        user: User(
          id: vendor['id'] as String,
          name: vendor['name'] as String,
          email: vendor['email'] as String,
          role: UserRole.vendedor,
          level: level,
        ),
        currentXp: currentLevelXpProgress,
        nextLevelXp: nextLevelXp,
        dailyScore: dailyScore,
        weeklyScore: weeklyScore,
        dailyTrend: '+10%',
        weeklyTrend: '+15%',
        goals: goals,
        nextAchievements: achievements,
        recentXpEvents: xpEvents,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GamificationDashboard extends StatelessWidget {
  const GamificationDashboard({super.key});

  String _friendlyError(String? raw) {
    if (raw == null) return 'Erro desconhecido';
    if (raw.contains('connection timeout') || raw.contains('SocketException')) {
      return 'Sem conexão com o servidor.\nVerifique se a API está rodando.';
    }
    if (raw.contains('404')) return 'Recurso não encontrado.';
    if (raw.contains('401') || raw.contains('403')) return 'Sessão expirada. Faça login novamente.';
    if (raw.contains('500')) return 'Erro interno do servidor.';
    return 'Ocorreu um erro. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    // Resolve vendorId from auth
    final authState = context.read<AuthBloc>().state;
    final vendorId = authState is AuthAuthenticated ? authState.user.id : 'current';

    return BlocProvider(
      create: (_) => GamificationDashboardCubit(
        repository: getIt<GamificationRepository>(),
      )..load(vendorId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Gamificação', style: AppTypography.displaySmall),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: BlocBuilder<GamificationDashboardCubit,
            GamificationDashboardState>(
          builder: (context, state) {
            // Skeleton loading
            if (state.isLoading && state.user == null) {
              return _buildSkeleton();
            }

            // Error state with retry
            if (state.error != null && state.user == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.statusError),
                    const SizedBox(height: 12),
                    Text(_friendlyError(state.error),
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<GamificationDashboardCubit>().load(vendorId),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<GamificationDashboardCubit>().load(vendorId),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _LevelBadge(
                    level: state.user?.level ?? 1,
                    currentXp: state.currentXp,
                    nextLevelXp: state.nextLevelXp,
                    progress: state.xpProgress,
                  ),
                  const SizedBox(height: 24),
                  _ScoreCards(
                    dailyScore: state.dailyScore,
                    weeklyScore: state.weeklyScore,
                    dailyTrend: state.dailyTrend,
                    weeklyTrend: state.weeklyTrend,
                  ),
                  const SizedBox(height: 24),
                  _GoalProgressSection(goals: state.goals),
                  const SizedBox(height: 24),
                  _NextAchievements(achievements: state.nextAchievements),
                  const SizedBox(height: 24),
                  _RecentActivity(events: state.recentXpEvents),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Level badge skeleton
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.xlBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        // Score cards skeleton
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 90)),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonBox(height: 90)),
          ],
        ),
        const SizedBox(height: 24),
        _SkeletonBox(height: 140),
        const SizedBox(height: 24),
        _SkeletonBox(height: 200),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Level Badge + XP Bar
// ---------------------------------------------------------------------------

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    required this.progress,
  });

  final int level;
  final int currentXp;
  final int nextLevelXp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF5B21B6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$level',
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Nivel $level', style: AppTypography.displaySmall),
          const SizedBox(height: 4),
          Text(
            '$currentXp / $nextLevelXp XP',
            style: AppTypography.label,
          ),
          const SizedBox(height: 16),

          // Animated XP progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.smBorder,
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: AppColors.muted,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(value * 100).toInt()}%',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Faltam ${nextLevelXp - currentXp} XP',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Score Cards
// ---------------------------------------------------------------------------

class _ScoreCards extends StatelessWidget {
  const _ScoreCards({
    required this.dailyScore,
    required this.weeklyScore,
    this.dailyTrend,
    this.weeklyTrend,
  });

  final int dailyScore;
  final int weeklyScore;
  final String? dailyTrend;
  final String? weeklyTrend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Pontos Hoje',
            value: '$dailyScore',
            icon: Icons.today,
            trend: dailyTrend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Pontos Semana',
            value: '$weeklyScore',
            icon: Icons.date_range,
            trend: weeklyTrend,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goal Progress
// ---------------------------------------------------------------------------

class _GoalProgressSection extends StatelessWidget {
  const _GoalProgressSection({required this.goals});

  final List<SellerGoalProgress> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minhas Metas', style: AppTypography.displaySmall),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: goals.indexed.map((entry) {
              final (index, goal) = entry;
              return Column(
                children: [
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                goal.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(goal.progress * 100).round()}%',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: AppRadius.smBorder,
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 8,
                            backgroundColor: AppColors.muted,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${goal.formattedCurrent} / ${goal.formattedTarget}',
                          style: AppTypography.label,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Next Achievements Preview
// ---------------------------------------------------------------------------

class _NextAchievements extends StatelessWidget {
  const _NextAchievements({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proximas Conquistas', style: AppTypography.displaySmall),
        const SizedBox(height: 12),
        Row(
          children: achievements.take(3).map((a) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: a != achievements.last ? 10 : 0,
                ),
                child: _LockedAchievementCard(achievement: a),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LockedAchievementCard extends StatelessWidget {
  const _LockedAchievementCard({required this.achievement});

  final Achievement achievement;

  IconData _resolveIcon() {
    return switch (achievement.iconName) {
      'military_tech' => Icons.military_tech,
      'directions_run' => Icons.directions_run,
      'emoji_events' => Icons.emoji_events,
      _ => Icons.lock_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _resolveIcon(),
                size: 32,
                color: AppColors.mutedForeground.withValues(alpha: 0.4),
              ),
              Icon(
                Icons.lock,
                size: 16,
                color: AppColors.mutedForeground.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '+${achievement.xpReward} XP',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent XP Activity
// ---------------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.events});

  final List<XpEvent> events;

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atras';
    if (diff.inHours < 24) return '${diff.inHours}h atras';
    return '${diff.inDays}d atras';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atividade Recente', style: AppTypography.displaySmall),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: events.take(5).indexed.map((entry) {
              final (index, event) = entry;
              return Column(
                children: [
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bolt,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.description,
                                style: AppTypography.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _timeAgo(event.createdAt),
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${event.xpAmount} XP',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder box
// ---------------------------------------------------------------------------

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
