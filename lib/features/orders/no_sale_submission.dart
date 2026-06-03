enum NoSaleReason {
  clienteClosed('Cliente fechado', 'cliente_fechado'),
  semInteresse('Sem interesse', 'sem_interesse'),
  compraraDepois('Comprará depois', 'vai_comprar_depois');

  const NoSaleReason(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

String buildNoSaleRoutePath(String routeId) => '/routes/$routeId/no-sale';

Map<String, dynamic> buildNoSalePayload({
  required String clientId,
  required NoSaleReason reason,
}) {
  return {'clientId': clientId, 'visitReason': reason.apiValue};
}
