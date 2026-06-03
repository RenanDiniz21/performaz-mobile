import '../shared/models/user.dart';

String homeRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.gestor => '/manager',
    UserRole.vendedor => '/routes',
  };
}
