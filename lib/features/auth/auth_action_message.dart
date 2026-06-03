enum AuthAction { googleSignIn, selfRegistration, passwordRecovery }

String unavailableAuthActionMessage(AuthAction action) {
  return switch (action) {
    AuthAction.googleSignIn =>
      'Login com Google ainda nao esta habilitado neste ambiente.',
    AuthAction.selfRegistration =>
      'Cadastro de usuarios deve ser feito pelo painel web do gestor.',
    AuthAction.passwordRecovery =>
      'Recuperacao de senha ainda nao esta habilitada. Solicite redefinicao ao gestor.',
  };
}
