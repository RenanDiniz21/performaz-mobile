enum OrderSubmissionResult { synced, pendingSync }

Future<OrderSubmissionResult> submitOrderOnlineFirst({
  required Future<void> Function() createRemoteOrder,
  required Future<void> Function() savePendingOrder,
}) async {
  try {
    await createRemoteOrder();
    return OrderSubmissionResult.synced;
  } catch (_) {
    await savePendingOrder();
    return OrderSubmissionResult.pendingSync;
  }
}
