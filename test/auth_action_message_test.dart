import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/features/auth/auth_action_message.dart';

void main() {
  test('explains unavailable Google sign-in', () {
    expect(
      unavailableAuthActionMessage(AuthAction.googleSignIn),
      'Login com Google ainda nao esta habilitado neste ambiente.',
    );
  });

  test('explains unavailable self registration', () {
    expect(
      unavailableAuthActionMessage(AuthAction.selfRegistration),
      'Cadastro de usuarios deve ser feito pelo painel web do gestor.',
    );
  });

  test('explains unavailable password recovery', () {
    expect(
      unavailableAuthActionMessage(AuthAction.passwordRecovery),
      'Recuperacao de senha ainda nao esta habilitada. Solicite redefinicao ao gestor.',
    );
  });
}
