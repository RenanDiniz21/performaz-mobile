import 'package:flutter_test/flutter_test.dart';

import 'package:performaz/app/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PerformazApp());
    await tester.pumpAndSettle();

    expect(find.text('Performaz'), findsWidgets);
  });
}
