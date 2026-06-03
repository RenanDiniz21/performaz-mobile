import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:performaz/core/auth/auth_bloc.dart';
import 'package:performaz/core/auth/auth_repository.dart';
import 'package:performaz/shared/models/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const currentUser = User(
    id: 'vendor-1',
    name: 'Carlos Silva',
    email: 'carlos@performaz.com',
    role: UserRole.vendedor,
    phone: '(11) 99999-0000',
  );

  const updatedUser = User(
    id: 'vendor-1',
    name: 'Carlos Santos',
    email: 'carlos@performaz.com',
    role: UserRole.vendedor,
    phone: '(11) 98888-0000',
  );

  blocTest<AuthBloc, AuthState>(
    'updates the authenticated user after profile save',
    build: () {
      final repository = MockAuthRepository();
      when(
        () => repository.updateVendorProfile(
          vendorId: 'vendor-1',
          name: 'Carlos Santos',
          phone: '(11) 98888-0000',
        ),
      ).thenAnswer((_) async => updatedUser);
      return AuthBloc(authRepository: repository);
    },
    seed: () => const AuthAuthenticated(currentUser),
    act: (bloc) => bloc.add(
      const AuthProfileUpdateRequested(
        name: 'Carlos Santos',
        phone: '(11) 98888-0000',
      ),
    ),
    expect: () => const [AuthAuthenticated(updatedUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'keeps the authenticated user after password change succeeds',
    build: () {
      final repository = MockAuthRepository();
      when(
        () => repository.changeVendorPassword(
          currentPassword: 'vendor123',
          newPassword: 'newVendor123',
        ),
      ).thenAnswer((_) async {});
      return AuthBloc(authRepository: repository);
    },
    seed: () => const AuthAuthenticated(currentUser),
    act: (bloc) => bloc.add(
      const AuthPasswordChangeRequested(
        currentPassword: 'vendor123',
        newPassword: 'newVendor123',
      ),
    ),
    expect: () => const <AuthState>[],
    verify: (bloc) {
      verify(
        () => bloc.authRepository.changeVendorPassword(
          currentPassword: 'vendor123',
          newPassword: 'newVendor123',
        ),
      ).called(1);
      expect(bloc.state, const AuthAuthenticated(currentUser));
    },
  );
}
