class SellerGoalProgress {
  const SellerGoalProgress({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.type,
  });

  final String id;
  final String title;
  final double current;
  final double target;
  final String type;

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;

  String get formattedCurrent => _formatValue(current);
  String get formattedTarget => _formatValue(target);

  String _formatValue(double value) {
    if (type == 'receita') {
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    return value.toInt().toString();
  }
}

List<SellerGoalProgress> sellerGoalsFromApi(List<dynamic> rows) {
  return rows
      .whereType<Map<String, dynamic>>()
      .where((goal) => goal['type'] == 'receita' || goal['type'] == 'vendas')
      .map((goal) {
    final type = goal['type'] as String;
    final period = goal['period'] as String? ?? '';
    return SellerGoalProgress(
      id: goal['id'] as String,
      title: '${_goalTypeLabel(type)} ${_periodLabel(period)}'.trim(),
      current: (goal['current'] as num? ?? 0).toDouble(),
      target: (goal['target'] as num? ?? 0).toDouble(),
      type: type,
    );
  }).toList();
}

String _goalTypeLabel(String type) {
  return switch (type) {
    'receita' => 'Receita',
    'vendas' => 'Vendas',
    _ => type,
  };
}

String _periodLabel(String period) {
  return switch (period) {
    'mensal' => 'mensal',
    'semanal' => 'semanal',
    'diario' => 'diaria',
    _ => period,
  };
}
