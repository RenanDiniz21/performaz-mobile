import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../app/di.dart';
import '../../core/repositories/manager_repository.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _NotificationRecord {
  const _NotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    required this.sentAt,
  });

  final String id;
  final String title;
  final String message;
  final String target; // "all" or seller name
  final DateTime sentAt;
}

class _SellerOption {
  const _SellerOption(this.id, this.name);
  final String id;
  final String name;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NotificationsState {
  const NotificationsState({
    this.history = const [],
    this.sellers = const [],
    this.selectedSellerId,
    this.isSending = false,
    this.isLoading = true,
  });

  final List<_NotificationRecord> history;
  final List<_SellerOption> sellers;
  final String? selectedSellerId;
  final bool isSending;
  final bool isLoading;

  NotificationsState copyWith({
    List<_NotificationRecord>? history,
    List<_SellerOption>? sellers,
    String? selectedSellerId,
    bool? clearSelectedSeller,
    bool? isSending,
    bool? isLoading,
  }) {
    return NotificationsState(
      history: history ?? this.history,
      sellers: sellers ?? this.sellers,
      selectedSellerId: clearSelectedSeller == true
          ? null
          : (selectedSellerId ?? this.selectedSellerId),
      isSending: isSending ?? this.isSending,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required this.repository}) : super(const NotificationsState());

  final ManagerRepository repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final notifsData = await repository.fetchNotifications();
      final vendorsData = await repository.fetchVendors();

      final sellers = vendorsData
          .map((v) => _SellerOption(v['id'] as String, v['name'] as String))
          .toList();

      final history = notifsData.map((n) {
        final target = n['targetAll'] == true
            ? 'Todos'
            : 'Específico';
        final sentAt = n['createdAt'] != null
            ? DateTime.parse(n['createdAt'].toString())
            : DateTime.now();

        return _NotificationRecord(
          id: n['id'] as String,
          title: n['title'] as String,
          message: n['message'] as String,
          target: target,
          sentAt: sentAt,
        );
      }).toList();

      history.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      emit(state.copyWith(
        sellers: sellers,
        history: history,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void selectSeller(String? id) {
    if (id == null) {
      emit(state.copyWith(clearSelectedSeller: true));
    } else {
      emit(state.copyWith(selectedSellerId: id));
    }
  }

  Future<void> send(String title, String message) async {
    if (title.isEmpty || message.isEmpty) return;

    emit(state.copyWith(isSending: true));
    try {
      final targetAll = state.selectedSellerId == null;
      final vendorIds = targetAll ? null : [state.selectedSellerId!];

      await repository.sendNotification(
        title: title,
        message: message,
        targetAll: targetAll,
        vendorIds: vendorIds,
      );

      await load();
      emit(state.copyWith(isSending: false, clearSelectedSeller: true));
    } catch (_) {
      emit(state.copyWith(isSending: false));
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(
        repository: getIt<ManagerRepository>(),
      )..load(),
      child: const _NotificationsBody(),
    );
  }
}

class _NotificationsBody extends StatefulWidget {
  const _NotificationsBody();

  @override
  State<_NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<_NotificationsBody> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
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
                  Text('Notificações', style: AppTypography.displayMedium),
                  const SizedBox(height: 24),

                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _ComposeCard(
                            titleCtrl: _titleCtrl,
                            messageCtrl: _messageCtrl,
                            sellers: state.sellers,
                            selectedSellerId: state.selectedSellerId,
                            isSending: state.isSending,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _HistoryCard(history: state.history),
                        ),
                      ],
                    )
                  else ...[
                    _ComposeCard(
                      titleCtrl: _titleCtrl,
                      messageCtrl: _messageCtrl,
                      sellers: state.sellers,
                      selectedSellerId: state.selectedSellerId,
                      isSending: state.isSending,
                    ),
                    const SizedBox(height: 24),
                    _HistoryCard(history: state.history),
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
// Compose card
// ---------------------------------------------------------------------------

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.titleCtrl,
    required this.messageCtrl,
    required this.sellers,
    required this.selectedSellerId,
    required this.isSending,
  });

  final TextEditingController titleCtrl;
  final TextEditingController messageCtrl;
  final List<_SellerOption> sellers;
  final String? selectedSellerId;
  final bool isSending;

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
          Text('Nova Notificação',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: 'Título',
              filled: true,
              fillColor: AppColors.muted,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdBorder,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Message
          TextField(
            controller: messageCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Mensagem',
              filled: true,
              fillColor: AppColors.muted,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdBorder,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Target selector
          DropdownButtonFormField<String>(
            initialValue: selectedSellerId,
            decoration: InputDecoration(
              labelText: 'Destinatário',
              filled: true,
              fillColor: AppColors.muted,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdBorder,
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos os vendedores'),
              ),
              ...sellers.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  )),
            ],
            onChanged: (v) =>
                context.read<NotificationsCubit>().selectSeller(v),
          ),
          const SizedBox(height: 20),

          // Send button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: isSending
                  ? null
                  : () {
                      context.read<NotificationsCubit>().send(
                            titleCtrl.text,
                            messageCtrl.text,
                          );
                      titleCtrl.clear();
                      messageCtrl.clear();
                    },
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(isSending ? 'Enviando...' : 'Enviar Notificação'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History card
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});
  final List<_NotificationRecord> history;

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
          Text('Histórico de Envios',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Nenhuma notificação enviada',
                    style: AppTypography.label),
              ),
            )
          else
            ...history.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: AppRadius.smBorder,
                              ),
                              child: Text(n.target,
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(n.message, style: AppTypography.bodySmall),
                        const SizedBox(height: 6),
                        Text(
                          _dateFormat.format(n.sentAt),
                          style: AppTypography.label,
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
