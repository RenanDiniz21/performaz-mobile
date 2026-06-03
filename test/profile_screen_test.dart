import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:performaz/core/auth/auth_bloc.dart';
import 'package:performaz/core/auth/auth_repository.dart';
import 'package:performaz/features/auth/profile_screen.dart';
import 'package:performaz/shared/models/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('profile screen opens the edit profile dialog', (tester) async {
    const user = User(
      id: 'vendor-1',
      name: 'Carlos Silva',
      email: 'carlos@performaz.com',
      role: UserRole.vendedor,
      phone: '(11) 99999-0000',
    );
    final repository = MockAuthRepository();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

    final authBloc = AuthBloc(authRepository: repository)
      ..add(const AuthCheckRequested());
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Salvar perfil'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Carlos Silva'), findsOneWidget);
  });

  testWidgets('profile screen opens the change password dialog', (
    tester,
  ) async {
    const user = User(
      id: 'vendor-1',
      name: 'Carlos Silva',
      email: 'carlos@performaz.com',
      role: UserRole.vendedor,
      phone: '(11) 99999-0000',
    );
    final repository = MockAuthRepository();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

    final authBloc = AuthBloc(authRepository: repository)
      ..add(const AuthCheckRequested());
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();

    expect(find.text('Salvar senha'), findsOneWidget);
    expect(find.text('Senha atual'), findsOneWidget);
    expect(find.text('Nova senha'), findsOneWidget);
  });
}
