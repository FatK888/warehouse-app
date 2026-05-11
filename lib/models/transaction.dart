class Transaction {
  final int? id;
  final String type;
  final String? buyerName;
  final String? buyerContact;
  final String? buyerPhone;
  final String? buyerRemark;
  final int totalQty;
  final double totalAmount;
  final String? createdAt;

  const Transaction({
    this.id,
    required this.type,
    this.buyerName,
    this.buyerContact,
    this.buyerPhone,
    this.buyerRemark,
    required this.totalQty,
    required this.totalAmount,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'buyer_name': buyerName,
      'buyer_contact': buyerContact,
      'buyer_phone': buyerPhone,
      'buyer_remark': buyerRemark,
      'total_qty': totalQty,
      'total_amount': totalAmount,
      'created_at': createdAt ?? _nowFormatted(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      buyerName: map['buyer_name'] as String?,
      buyerContact: map['buyer_contact'] as String?,
      buyerPhone: map['buyer_phone'] as String?,
      buyerRemark: map['buyer_remark'] as String?,
      totalQty: map['total_qty'] as int,
      totalAmount: (map['total_amount'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
    );
  }

  static String _nowFormatted() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}
