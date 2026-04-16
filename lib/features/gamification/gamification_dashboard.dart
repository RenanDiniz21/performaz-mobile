import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/achievement.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/stat_card.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GamificationDashboardState extends Equatable {
  const GamificationDashboardState({
    this.user,
    this.currentXp = 0,
    this.nextLevelXp = 1000,
    this.dailyScore = 0,
    this.weeklyScore = 0,
    this.dailyTrend,
    this.weeklyTrend,
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
  final List<Achievement> nextAchievements;
  final List<XpEvent> recentXpEvents;
  final bool isLoading;

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
    List<Achievement>? nextAchievements,
    List<XpEvent>? recentXpEvents,
    bool? isLoading,
  }) {
    return GamificationDashboardState(
      user: user ?? this.user,
      currentXp: currentXp ?? this.currentXp,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      dailyScore: dailyScore ?? this.dailyScore,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      dailyTrend: dailyTrend ?? this.dailyTrend,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      nextAchievements: nextAchievements ?? this.nextAchievements,
      recentXpEvents: recentXpEvents ?? this.recentXpEvents,
      isLoading: isLoading ?? this.isLoading,
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
        nextAchievements,
        recentXpEvents,
        isLoading,
      ];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class GamificationDashboardCubit extends Cubit<GamificationDashboardState> {
  GamificationDashboardCubit() : super(const GamificationDashboardState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));

    // TODO: replace with real repository call
    await Future<void>.delayed(const Duration(milliseconds: 600));

    emit(state.copyWith(
      isLoading: false,
      user: const User(
        id: '1',
        name: 'Carlos Silva',
        email: 'carlos@performaz.com',
        role: UserRole.vendedor,
        level: 7,
        xp: 3420,
      ),
      currentXp: 3420,
      nextLevelXp: 5000,
      dailyScore: 245,
      weeklyScore: 1830,
      dailyTrend: '+18% vs ontem',
      weeklyTrend: '+12% vs semana anterior',
      nextAchievements: const [
        Achievement(
          id: 'a1',
          type: AchievementType.centuriao,
          title: 'Centuriao',
          description: 'Realize 100 vendas',
          iconName: 'military_tech',
          xpReward: 500,
        ),
        Achievement(
          id: 'a2',
          type: AchievementType.maratonista,
          title: 'Maratonista',
          description: '20 visitas em um dia',
          iconName: 'directions_run',
          xpReward: 300,
        ),
        Achievement(
          id: 'a3',
          type: AchievementType.topSemanal,
          title: 'Top Semanal',
          description: 'Seja #1 da semana',
          iconName: 'emoji_events',
          xpReward: 400,
        ),
      ],
      recentXpEvents: [
        XpEvent(
          id: 'e1',
          description: 'Venda registrada — Cliente ABC',
          xpAmount: 50,
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        XpEvent(
          id: 'e2',
          description: 'Visita concluida',
          xpAmount: 20,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        XpEvent(
          id: 'e3',
          description: 'Conquista desbloqueada',
          xpAmount: 200,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        XpEvent(
          id: 'e4',
          description: 'Pedido entregue',
          xpAmount: 30,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        XpEvent(
          id: 'e5',
          description: 'Check-in matinal',
          xpAmount: 10,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    ));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GamificationDashboard extends StatelessWidget {
  const GamificationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GamificationDashboardCubit()..load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Gamificacao', style: AppTypography.displaySmall),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: BlocBuilder<GamificationDashboardCubit,
            GamificationDashboardState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  context.read<GamificationDashboardCubit>().load(),
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
