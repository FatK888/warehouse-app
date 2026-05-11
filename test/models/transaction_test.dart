import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/transaction.dart';
import 'package:warehouse/models/transaction_item.dart';
import 'package:warehouse/models/imei_unit.dart';

void main() {
  group('Transaction', () {
    test('fromMap for IN type', () {
      final map = {
        'id': 1,
        'type': 'IN',
        'buyer_name': null,
        'buyer_contact': null,
        'buyer_phone': null,
        'buyer_remark': null,
        'total_qty': 10,
        'total_amount': 8990.0,
        'created_at': '2026-05-11 10:00:00',
      };

      final tx = Transaction.fromMap(map);

      expect(tx.id, 1);
      expect(tx.type, 'IN');
      expect(tx.buyerName, isNull);
      expect(tx.totalQty, 10);
      expect(tx.totalAmount, 8990.0);
    });

    test('fromMap for OUT type with buyer', () {
      final map = {
        'id': 2,
        'type': 'OUT',
        'buyer_name': '豐澤電器',
        'buyer_contact': '陳生',
        'buyer_phone': '91234567',
        'buyer_remark': '急單',
        'total_qty': 5,
        'total_amount': 79995.0,
        'created_at': '2026-05-11 14:00:00',
      };

      final tx = Transaction.fromMap(map);

      expect(tx.type, 'OUT');
      expect(tx.buyerName, '豐澤電器');
      expect(tx.buyerContact, '陳生');
      expect(tx.buyerPhone, '91234567');
      expect(tx.buyerRemark, '急單');
    });

    test('toMap should serialize correctly', () {
      final tx = Transaction(
        type: 'OUT',
        buyerName: '豐澤電器',
        totalQty: 5,
        totalAmount: 79995.0,
      );

      final map = tx.toMap();

      expect(map['type'], 'OUT');
      expect(map['buyer_name'], '豐澤電器');
      expect(map['total_qty'], 5);
      expect(map['total_amount'], 79995.0);
    });
  });

  group('TransactionItem', () {
    test('fromMap with scode_list', () {
      final map = {
        'id': 1,
        'transaction_id': 1,
        'product_id': 3,
        'qty': 5,
        'unit_price': 15999.0,
        'subtotal': 79995.0,
        'scode_list': '["65465321654321","65465321654322"]',
      };

      final item = TransactionItem.fromMap(map);

      expect(item.transactionId, 1);
      expect(item.productId, 3);
      expect(item.qty, 5);
      expect(item.unitPrice, 15999.0);
      expect(item.subtotal, 79995.0);
      expect(item.scodeList, ['65465321654321', '65465321654322']);
    });

    test('fromMap with null scode_list', () {
      final map = {
        'id': 1,
        'transaction_id': 1,
        'product_id': 3,
        'qty': 5,
        'unit_price': 15999.0,
        'subtotal': 79995.0,
        'scode_list': null,
      };

      final item = TransactionItem.fromMap(map);

      expect(item.scodeList, isNull);
    });

    test('toMap with scode list', () {
      final item = TransactionItem(
        transactionId: 1,
        productId: 3,
        qty: 5,
        unitPrice: 15999.0,
        subtotal: 79995.0,
        scodeList: ['65465321654321'],
      );

      final map = item.toMap();

      expect(map['scode_list'], '["65465321654321"]');
    });
  });

  group('ImeiUnit', () {
    test('fromMap in_stock', () {
      final map = {
        'id': 1,
        'product_id': 3,
        'scode': '65465321654321',
        'status': 'in_stock',
        'inbound_tx_id': 1,
        'outbound_tx_id': null,
      };

      final unit = ImeiUnit.fromMap(map);

      expect(unit.scode, '65465321654321');
      expect(unit.status, 'in_stock');
      expect(unit.inboundTxId, 1);
      expect(unit.outboundTxId, isNull);
    });

    test('fromMap sold_out', () {
      final map = {
        'id': 2,
        'product_id': 3,
        'scode': '65465321654322',
        'status': 'sold_out',
        'inbound_tx_id': 1,
        'outbound_tx_id': 2,
      };

      final unit = ImeiUnit.fromMap(map);

      expect(unit.status, 'sold_out');
      expect(unit.outboundTxId, 2);
    });
  });

  group('BatchItem', () {
    test('subtotal should be qty * unitPrice', () {
      final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
      final item = BatchItem(product: product, qty: 3, unitPrice: 100.0);
      expect(item.subtotal, 300.0);
    });

    test('addScode should increment qty', () {
      final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
      final item = BatchItem(product: product, qty: 1, unitPrice: 100.0);
      item.addScode('123456789012345');
      expect(item.qty, 2);
      expect(item.scodes, contains('123456789012345'));
    });
  });
}
