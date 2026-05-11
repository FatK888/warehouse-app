import 'dart:convert';
import 'package:warehouse/models/product.dart';

class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final int qty;
  final double unitPrice;
  final double subtotal;
  final List<String>? scodeList;

  const TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
    this.scodeList,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'qty': qty,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'scode_list': scodeList != null ? jsonEncode(scodeList) : null,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    List<String>? parseScodeList(dynamic value) {
      if (value == null) return null;
      return (jsonDecode(value as String) as List).cast<String>();
    }

    return TransactionItem(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      productId: map['product_id'] as int,
      qty: map['qty'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      scodeList: parseScodeList(map['scode_list']),
    );
  }
}

class BatchItem {
  final Product product;
  int qty;
  double unitPrice;
  final List<String> scodes;

  BatchItem({
    required this.product,
    this.qty = 1,
    this.unitPrice = 0.0,
    List<String>? scodes,
  }) : scodes = scodes ?? [];

  double get subtotal => qty * unitPrice;

  void addScode(String scode) {
    scodes.add(scode);
    qty++;
  }
}
