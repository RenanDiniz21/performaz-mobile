import 'dart:convert';

import 'package:drift/drift.dart';

part 'local_database.g.dart';

// --- Table definitions for offline storage ---

class PendingCheckins extends Table {
  TextColumn get id => text()();
  TextColumn get routeId => text().nullable()();
  TextColumn get clientId => text()();
  DateTimeColumn get checkinAt => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingOrders extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get sellerId => text()();
  TextColumn get itemsJson => text()(); // JSON-serialized items
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedClients extends Table {
  TextColumn get id => text()();
  TextColumn get dataJson => text()(); // Full client JSON
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [PendingCheckins, PendingOrders, CachedClients, CachedProducts],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(pendingCheckins, pendingCheckins.routeId);
          }
        },
      );

  // --- Pending checkins ---
  Future<int> getPendingCheckinCount() async {
    final count = countAll();
    final query = selectOnly(pendingCheckins)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<PendingCheckin>> getUnsyncedCheckins() {
    return (select(pendingCheckins)
          ..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> insertCheckin(PendingCheckinsCompanion checkin) =>
      into(pendingCheckins).insert(checkin);

  Future<void> markCheckinSynced(String id) {
    return (update(pendingCheckins)..where((t) => t.id.equals(id)))
        .write(const PendingCheckinsCompanion(synced: Value(true)));
  }

  // --- Pending orders ---
  Future<int> getPendingOrderCount() async {
    final count = countAll();
    final query = selectOnly(pendingOrders)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<PendingOrder>> getUnsyncedOrders() {
    return (select(pendingOrders)
          ..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> insertOrder(PendingOrdersCompanion order) =>
      into(pendingOrders).insert(order);

  Future<void> markOrderSynced(String id) {
    return (update(pendingOrders)..where((t) => t.id.equals(id)))
        .write(const PendingOrdersCompanion(synced: Value(true)));
  }

  // --- Cached clients ---
  Future<void> cacheClient(String id, Map<String, dynamic> data) {
    return into(cachedClients).insertOnConflictUpdate(
      CachedClientsCompanion.insert(
        id: id,
        dataJson: jsonEncode(data),
        cachedAt: DateTime.now(),
      ),
    );
  }

  Future<List<CachedClient>> getAllCachedClients() =>
      select(cachedClients).get();

  // --- Cached products ---
  Future<void> cacheProduct(String id, Map<String, dynamic> data) {
    return into(cachedProducts).insertOnConflictUpdate(
      CachedProductsCompanion.insert(
        id: id,
        dataJson: jsonEncode(data),
        cachedAt: DateTime.now(),
      ),
    );
  }

  Future<List<CachedProduct>> getAllCachedProducts() =>
      select(cachedProducts).get();

  // --- Aggregate pending count ---
  Future<int> getTotalPendingCount() async {
    final checkins = await getPendingCheckinCount();
    final orders = await getPendingOrderCount();
    return checkins + orders;
  }
}
