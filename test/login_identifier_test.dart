import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/core/auth/login_identifier.dart';

void main() {
  test('classifies manager email and vendor matricula identifiers', () {
    expect(
      loginIdentifierKind('admin@performaz.com'),
      LoginIdentifierKind.managerEmail,
    );
    expect(loginIdentifierKind('V001'), LoginIdentifierKind.vendorMatricula);
  });

  test('validates empty and malformed login identifiers', () {
    expect(validateLoginIdentifier(''), 'Informe seu e-mail ou matricula');
    expect(validateLoginIdentifier('admin@'), 'Informe um e-mail valido');
    expect(validateLoginIdentifier('V001'), null);
    expect(validateLoginIdentifier('admin@performaz.com'), null);
  });
}
