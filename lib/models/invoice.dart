class Invoice {
  final int? id;
  final String invNo;
  final String type;
  final int? supplierId;
  final int userId;
  final int totalQty;
  final double totalAmount;
  final String? remark;
  final String createdAt;
  final String filename;

  const Invoice({
    this.id,
    required this.invNo,
    required this.type,
    this.supplierId,
    required this.userId,
    required this.totalQty,
    required this.totalAmount,
    this.remark,
    required this.createdAt,
    required this.filename,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inv_no': invNo,
      'type': type,
      'supplier_id': supplierId,
      'user_id': userId,
      'total_qty': totalQty,
      'total_amount': totalAmount,
      'remark': remark,
      'created_at': createdAt,
      'filename': filename,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invNo: map['inv_no'] as String,
      type: map['type'] as String,
      supplierId: map['supplier_id'] as int?,
      userId: map['user_id'] as int,
      totalQty: map['total_qty'] as int,
      totalAmount: (map['total_amount'] as num).toDouble(),
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String,
      filename: map['filename'] as String,
    );
  }
}

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final String productInfo;
  final int qty;
  final double unitPrice;
  final double subtotal;

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productInfo,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'product_info': productInfo,
      'qty': qty,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      productInfo: map['product_info'] as String,
      qty: map['qty'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
