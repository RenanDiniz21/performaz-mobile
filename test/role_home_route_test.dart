import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/app/role_home_route.dart';
import 'package:performaz/shared/models/user.dart';

void main() {
  test('sends sellers to the seller route flow', () {
    expect(homeRouteForRole(UserRole.vendedor), '/routes');
  });

  test('sends managers to the manager handoff route', () {
    expect(homeRouteForRole(UserRole.gestor), '/manager');
  });
}
