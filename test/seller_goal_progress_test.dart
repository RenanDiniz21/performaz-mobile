import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/features/gamification/seller_goal_progress.dart';

void main() {
  test('sellerGoalsFromApi maps active sales and revenue goals', () {
    final goals = sellerGoalsFromApi([
      {
        'id': 'goal-revenue',
        'type': 'receita',
        'period': 'mensal',
        'target': 30000,
        'current': 22500,
      },
      {
        'id': 'goal-sales',
        'type': 'vendas',
        'period': 'mensal',
        'target': 20,
        'current': 15,
      },
      {
        'id': 'goal-visits',
        'type': 'visitas',
        'period': 'mensal',
        'target': 10,
        'current': 4,
      },
    ]);

    expect(goals, hasLength(2));
    expect(goals.first.title, 'Receita mensal');
    expect(goals.first.progress, 0.75);
    expect(goals.first.formattedCurrent, 'R\$ 22500,00');
    expect(goals.first.formattedTarget, 'R\$ 30000,00');
    expect(goals.last.title, 'Vendas mensal');
    expect(goals.last.formattedCurrent, '15');
    expect(goals.last.formattedTarget, '20');
  });
}
