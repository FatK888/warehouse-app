class StockItem {
  final int? id;
  final int productId;
  final String? scode;
  final String status; // 'in_stock' | 'sold_out'
  final double? unitPrice;
  final String inboundAt;
  final String? outboundAt;
  final int? inboundTxId;
  final int? outboundTxId;

  const StockItem({
    this.id,
    required this.productId,
    this.scode,
    this.status = 'in_stock',
    this.unitPrice,
    required this.inboundAt,
    this.outboundAt,
    this.inboundTxId,
    this.outboundTxId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'scode': scode,
      'status': status,
      'unit_price': unitPrice,
      'inbound_at': inboundAt,
      'outbound_at': outboundAt,
      'inbound_tx_id': inboundTxId,
      'outbound_tx_id': outboundTxId,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      scode: map['scode'] as String?,
      status: map['status'] as String,
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      inboundAt: map['inbound_at'] as String,
      outboundAt: map['outbound_at'] as String?,
      inboundTxId: map['inbound_tx_id'] as int?,
      outboundTxId: map['outbound_tx_id'] as int?,
    );
  }
}
