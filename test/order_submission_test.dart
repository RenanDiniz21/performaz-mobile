import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/features/orders/order_submission.dart';

void main() {
  test('submitOrderOnlineFirst returns synced when remote submission succeeds', () async {
    var remoteCalls = 0;
    var pendingCalls = 0;

    final result = await submitOrderOnlineFirst(
      createRemoteOrder: () async => remoteCalls++,
      savePendingOrder: () async => pendingCalls++,
    );

    expect(result, OrderSubmissionResult.synced);
    expect(remoteCalls, 1);
    expect(pendingCalls, 0);
  });

  test('submitOrderOnlineFirst falls back to pending storage when remote fails', () async {
    var pendingCalls = 0;

    final result = await submitOrderOnlineFirst(
      createRemoteOrder: () async => throw Exception('offline'),
      savePendingOrder: () async => pendingCalls++,
    );

    expect(result, OrderSubmissionResult.pendingSync);
    expect(pendingCalls, 1);
  });
}
