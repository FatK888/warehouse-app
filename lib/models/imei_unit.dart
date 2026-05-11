class ImeiUnit {
  final int? id;
  final int productId;
  final String scode;
  final String status;
  final int? inboundTxId;
  final int? outboundTxId;

  const ImeiUnit({
    this.id,
    required this.productId,
    required this.scode,
    this.status = 'in_stock',
    this.inboundTxId,
    this.outboundTxId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'scode': scode,
      'status': status,
      'inbound_tx_id': inboundTxId,
      'outbound_tx_id': outboundTxId,
    };
  }

  factory ImeiUnit.fromMap(Map<String, dynamic> map) {
    return ImeiUnit(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      scode: map['scode'] as String,
      status: map['status'] as String,
      inboundTxId: map['inbound_tx_id'] as int?,
      outboundTxId: map['outbound_tx_id'] as int?,
    );
  }
}
