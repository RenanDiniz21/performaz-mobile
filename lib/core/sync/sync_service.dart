import 'dart:async';
import 'dart:convert';

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
        if (checkin.routeId == null) {
          _logger.w('Cannot sync checkin ${checkin.id}: missing routeId');
          continue;
        }

        await apiClient.post('/routes/${checkin.routeId}/checkin', data: {
          'clientId': checkin.clientId,
          'lat': checkin.latitude,
          'lng': checkin.longitude,
          'photoUrl': checkin.photoPath,
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
        final items = jsonDecode(order.itemsJson) as List<dynamic>;
        await apiClient.post('/orders', data: {
          'vendorId': order.sellerId,
          'clientId': order.clientId,
          'items': items,
          'notes': order.notes,
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
