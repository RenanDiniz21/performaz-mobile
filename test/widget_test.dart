import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:performaz/app/di.dart';
import 'package:performaz/app/app.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupDependencies(useInMemoryDatabase: true);
  });

  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PerformazApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Performaz'), findsWidgets);
  });
}
