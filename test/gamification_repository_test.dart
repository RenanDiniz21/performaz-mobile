import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/core/repositories/gamification_repository.dart';

void main() {
  test('achievementsFromVendorStats maps achievements from stats response', () {
    final achievements = achievementsFromVendorStats({
      'vendor': {'id': 'vendor-1'},
      'achievements': [
        {
          'id': 'achievement-1',
          'name': 'Primeira Venda',
          'description': 'Realize a primeira venda',
          'icon': 'shopping_cart',
          'xpReward': 100,
          'unlockedAt': '2026-06-02T12:00:00.000Z',
        },
      ],
      'xpHistory': [],
    });

    expect(achievements, hasLength(1));
    expect(achievements.single.id, 'achievement-1');
    expect(achievements.single.title, 'Primeira Venda');
    expect(achievements.single.isUnlocked, isTrue);
  });
}
