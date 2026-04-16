import 'dart:async';

import 'package:logger/logger.dart';

import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/local_database.dart';

class SyncService {
  SyncService({
    required this.apiClient,
    required this.localDb,
    required this.connectivity,
  }) {
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  final ApiClient apiClient;
  final LocalDatabase localDb;
  final ConnectivityService connectivity;

  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  void _onConnectivityChanged(bool isOnline) {
    if (isOnline) {
      syncAll();
    }
  }

  Future<void> syncAll() async {
    if (!connectivity.isOnline) return;

    _syncStatusController.add(SyncStatus.syncing);
    _logger.i('Starting sync...');

    try {
      await _syncCheckins();
      await _syncOrders();
      _syncStatusController.add(SyncStatus.synced);
      _logger.i('Sync complete');
    } catch (e) {
      _logger.e('Sync failed', error: e);
      _syncStatusController.add(SyncStatus.error);
    }
  }

  Future<void> _syncCheckins() async {
    final checkins = await localDb.getUnsyncedCheckins();
    for (final checkin in checkins) {
      try {
        await apiClient.post('/checkins', data: {
          'id': checkin.id,
          'client_id': checkin.clientId,
          'checkin_at': checkin.checkinAt.toIso8601String(),
          'latitude': checkin.latitude,
          'longitude': checkin.longitude,
          'photo_path': checkin.photoPath,
        });
        await localDb.markCheckinSynced(checkin.id);
      } catch (e) {
        _logger.w('Failed to sync checkin ${checkin.id}', error: e);
      }
    }
  }

  Future<void> _syncOrders() async {
    final orders = await localDb.getUnsyncedOrders();
    for (final order in orders) {
      try {
        await apiClient.post('/orders', data: {
          'id': order.id,
          'client_id': order.clientId,
          'seller_id': order.sellerId,
          'items': order.itemsJson,
          'notes': order.notes,
          'created_at': order.createdAt.toIso8601String(),
        });
        await localDb.markOrderSynced(order.id);
      } catch (e) {
        _logger.w('Failed to sync order ${order.id}', error: e);
      }
    }
  }

  Future<int> getPendingCount() => localDb.getTotalPendingCount();

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

enum SyncStatus { syncing, synced, error }
