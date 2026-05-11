import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/providers/batch_provider.dart';

void main() {
  late BatchProvider provider;

  setUp(() {
    provider = BatchProvider();
  });

  test('initial state should be empty', () {
    expect(provider.items, isEmpty);
    expect(provider.totalQty, 0);
    expect(provider.totalAmount, 0.0);
  });

  test('addItem should add new batch item', () {
    final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
    provider.addItem(product, qty: 2, unitPrice: 100.0);

    expect(provider.items.length, 1);
    expect(provider.items.first.qty, 2);
    expect(provider.totalQty, 2);
    expect(provider.totalAmount, 200.0);
  });

  test('addScodeToItem should increment qty and add scode', () {
    final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
    provider.addItem(product, qty: 1, unitPrice: 100.0);
    provider.addScodeToItem(0, '123456789012345');

    expect(provider.items.first.qty, 2);
    expect(provider.items.first.scodes, contains('123456789012345'));
  });

  test('removeItem should remove item from batch', () {
    final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
    provider.addItem(product, qty: 2, unitPrice: 100.0);
    provider.removeItem(0);

    expect(provider.items, isEmpty);
    expect(provider.totalQty, 0);
    expect(provider.totalAmount, 0.0);
  });

  test('updateQty should recalculate totals', () {
    final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
    provider.addItem(product, qty: 2, unitPrice: 100.0);
    provider.updateQty(0, 5);

    expect(provider.items.first.qty, 5);
    expect(provider.totalAmount, 500.0);
  });

  test('clear should reset everything', () {
    final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
    provider.addItem(product, qty: 2, unitPrice: 100.0);
    provider.clear();

    expect(provider.items, isEmpty);
    expect(provider.totalQty, 0);
    expect(provider.totalAmount, 0.0);
  });
}
