import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/repositories/gamification_repository.dart';
import '../../shared/models/achievement.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AchievementsState extends Equatable {
  const AchievementsState({
    this.achievements = const [],
    this.isLoading = true,
    this.justUnlockedId,
  });

  final List<Achievement> achievements;
  final bool isLoading;
  final String? justUnlockedId;

  AchievementsState copyWith({
    List<Achievement>? achievements,
    bool? isLoading,
    String? justUnlockedId,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      justUnlockedId: justUnlockedId,
    );
  }

  @override
  List<Object?> get props => [achievements, isLoading, justUnlockedId];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit({required this.repository})
      : super(const AchievementsState());

  final GamificationRepository repository;

  // ════════════════════════════════════════════════════════════════════
  // 🚧 MOCK — dados falsos para apresentação.
  //    Para integrar com a API real:
  //    1. Descomente a linha com repository.fetchAchievements(vendorId)
  //    2. Remova o Future.delayed e o mock achievements
  //    3. Rode: flutter pub get && dart run build_runner build
  // ════════════════════════════════════════════════════════════════════
  Future<void> load(String vendorId) async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // TODO(api): final achievements = await repository.fetchAchievements(vendorId);

    final now = DateTime.now();
    final achievements = [
      Achievement(
        id: 'a1',
        type: AchievementType.primeiraVendaDoDia,
        title: 'Primeira Venda',
        description: 'Registrou seu primeiro pedido',
        iconName: 'military_tech',
        xpReward: 100,
        unlockedAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'a2',
        type: AchievementType.dezClientesVisitados,
        title: 'Sequência de Fogo',
        description: '10 clientes visitados em um dia',
        iconName: 'directions_run',
        xpReward: 250,
        unlockedAt: now.subtract(const Duration(days: 12)),
      ),
      Achievement(
        id: 'a3',
        type: AchievementType.centuriao,
        title: 'Centurião',
        description: '100 vendas realizadas',
        iconName: 'emoji_events',
        xpReward: 500,
        unlockedAt: now.subtract(const Duration(days: 5)),
      ),
      Achievement(
        id: 'a4',
        type: AchievementType.maratonista,
        title: 'Maratonista',
        description: '20 visitas em um único dia',
        iconName: 'directions_run',
        xpReward: 300,
        unlockedAt: now.subtract(const Duration(days: 2)),
      ),
      const Achievement(
        id: 'a5',
        type: AchievementType.metaSemanalAtingida,
        title: 'Mestre das Metas',
        description: 'Bateu a meta semanal 3x seguidas',
        iconName: 'military_tech',
        xpReward: 750,
        // unlockedAt: null → bloqueada
      ),
      const Achievement(
        id: 'a6',
        type: AchievementType.topSemanal,
        title: 'Top 3 Regional',
        description: 'Ficou entre os 3 primeiros no ranking',
        iconName: 'emoji_events',
        xpReward: 1000,
        // unlockedAt: null → bloqueada
      ),
    ];

    emit(state.copyWith(isLoading: false, achievements: achievements));
  }

  void clearUnlockAnimation() {
    emit(state.copyWith(justUnlockedId: null));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AchievementsCubit(
        repository: getIt<GamificationRepository>(),
      )..load('current'),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Conquistas', style: AppTypography.displaySmall),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: BlocBuilder<AchievementsCubit, AchievementsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final unlocked =
                state.achievements.where((a) => a.isUnlocked).toList();
            final locked =
                state.achievements.where((a) => !a.isUnlocked).toList();
            final sorted = [...unlocked, ...locked];

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final achievement = sorted[index];
                final justUnlocked =
                    state.justUnlockedId == achievement.id;

                return _AchievementCard(
                  achievement: achievement,
                  playUnlockAnimation: justUnlocked,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievement Card
// ---------------------------------------------------------------------------

class _AchievementCard extends StatefulWidget {
  const _AchievementCard({
    required this.achievement,
    this.playUnlockAnimation = false,
  });

  final Achievement achievement;
  final bool playUnlockAnimation;

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.playUnlockAnimation) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    setState(() => _animating = true);
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _animating = false);
        context.read<AchievementsCubit>().clearUnlockAnimation();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AchievementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playUnlockAnimation && !oldWidget.playUnlockAnimation) {
      _triggerAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static IconData _resolveIcon(String name) {
    return switch (name) {
      'shopping_cart' => Icons.shopping_cart,
      'people' => Icons.people,
      'flag' => Icons.flag,
      'military_tech' => Icons.military_tech,
      'directions_run' => Icons.directions_run,
      'emoji_events' => Icons.emoji_events,
      _ => Icons.star,
    };
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final unlocked = a.isUnlocked;
    final dateFormat = DateFormat('dd/MM/yyyy');

    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: unlocked
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon area
          _buildIcon(unlocked),
          const SizedBox(height: 12),

          // Title
          Text(
            a.title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  unlocked ? AppColors.foreground : AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            a.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Bottom label
          if (unlocked)
            Text(
              'Desbloqueado ${dateFormat.format(a.unlockedAt!)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            )
          else
            Text(
              '+${a.xpReward} XP',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );

    if (_animating) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.scale(scale: _scaleAnim.value, child: child),
              // Confetti sparkle dots
              ...List.generate(8, (i) {
                final angle = i * (math.pi / 4);
                final radius = 40.0 * _scaleAnim.value;
                final opacity = (1.0 - _controller.value).clamp(0.0, 1.0);
                return Positioned(
                  left: 50 + radius * math.cos(angle),
                  top: 50 + radius * math.sin(angle),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            i.isEven ? AppColors.primary : AppColors.chart2,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        child: card,
      );
    }

    return card;
  }

  Widget _buildIcon(bool unlocked) {
    final icon = _resolveIcon(widget.achievement.iconName);

    Widget iconWidget = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: unlocked ? AppColors.accent : AppColors.muted,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 28,
        color: unlocked ? AppColors.primary : AppColors.mutedForeground,
      ),
    );

    if (!unlocked) {
      iconWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Stack(
          alignment: Alignment.center,
          children: [
            iconWidget,
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 20,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return iconWidget;
  }
}
