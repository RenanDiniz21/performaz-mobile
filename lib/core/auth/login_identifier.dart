enum LoginIdentifierKind { managerEmail, vendorMatricula }

LoginIdentifierKind loginIdentifierKind(String identifier) {
  return identifier.trim().contains('@')
      ? LoginIdentifierKind.managerEmail
      : LoginIdentifierKind.vendorMatricula;
}

String? validateLoginIdentifier(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Informe seu e-mail ou matricula';

  if (loginIdentifierKind(trimmed) == LoginIdentifierKind.managerEmail &&
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
    return 'Informe um e-mail valido';
  }

  return null;
}
