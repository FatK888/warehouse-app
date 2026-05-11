import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    final db = await AppDatabase.initialize(databaseFactoryFfi);
    await db.delete('transaction_items');
    await db.delete('imei_units');
    await db.delete('transactions');
    await db.delete('products');
  });

  test('insertProduct and findProduct', () async {
    final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max');
    final id = await Queries.insertProduct(product);
    expect(id, isPositive);

    final found = await Queries.findProduct('Apple', 'iPhone', '17Pro Max');
    expect(found, isNotNull);
    expect(found!.band, 'Apple');
  });

  test('searchProducts should match band/type/item', () async {
    await Queries.insertProduct(Product(band: 'Apple', type: 'iPhone', item: '17Pro Max'));
    await Queries.insertProduct(Product(band: 'Samsung', type: 'Phone', item: 'Galaxy S25'));

    final results = await Queries.searchProducts('Apple');
    expect(results.length, 1);
    expect(results.first.band, 'Apple');
  });

  test('getStock should return SUM(in) - SUM(out)', () async {
    final product = Product(band: 'Test', type: 'Item', item: 'X');
    final productId = await Queries.insertProduct(product);

    final db = AppDatabase.db;
    final txId = await db.insert('transactions', {
      'type': 'IN', 'total_qty': 10, 'total_amount': 1000,
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('transaction_items', {
      'transaction_id': txId, 'product_id': productId,
      'qty': 10, 'unit_price': 100, 'subtotal': 1000,
    });

    final stock = await Queries.getStock(productId);
    expect(stock, 10);
  });

  test('insertImeiUnit and findImeiUnit', () async {
    final product = Product(band: 'Test', type: 'Item', item: 'X');
    final productId = await Queries.insertProduct(product);

    await Queries.insertImeiUnit(productId, '123456789012345');
    final unit = await Queries.findImeiUnit('123456789012345');
    expect(unit, isNotNull);
    expect(unit!.status, 'in_stock');
  });
}
