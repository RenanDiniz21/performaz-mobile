import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/features/orders/no_sale_submission.dart';

void main() {
  test('buildNoSalePayload sends the Nest API no-sale contract', () {
    expect(
      buildNoSalePayload(
        clientId: 'client-1',
        reason: NoSaleReason.semInteresse,
      ),
      {'clientId': 'client-1', 'visitReason': 'sem_interesse'},
    );
  });

  test('buildNoSaleRoutePath requires the route-specific endpoint', () {
    expect(buildNoSaleRoutePath('route-1'), '/routes/route-1/no-sale');
  });
}
