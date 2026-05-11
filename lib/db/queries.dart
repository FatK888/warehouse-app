import 'package:sqflite/sqflite.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/imei_unit.dart';

class Queries {
  static Database? get _db => AppDatabase.initialized ? AppDatabase.db : null;

  // ── Products ──

  static Future<int> insertProduct(Product product) async {
    final db = _db;
    if (db == null) return -1;
    final existing = await findProductExact(product);
    if (existing != null) return existing.id!;
    return db.insert('products', product.toMap());
  }

  static Future<Product?> findProduct(
    String band, String type, String item, {
    String? size, String? color, String? model, String? spec,
  }) async {
    final db = _db;
    if (db == null) return null;
    final whereParts = <String>[];
    final whereArgs = <dynamic>[];
    whereParts.add('band = ?'); whereArgs.add(band);
    whereParts.add('type = ?'); whereArgs.add(type);
    whereParts.add('item = ?'); whereArgs.add(item);
    _addNullableCondition(whereParts, whereArgs, 'size', size);
    _addNullableCondition(whereParts, whereArgs, 'color', color);
    _addNullableCondition(whereParts, whereArgs, 'model', model);
    _addNullableCondition(whereParts, whereArgs, 'spec', spec);

    final results = await db.query('products',
      where: whereParts.join(' AND '), whereArgs: whereArgs, limit: 1);
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  static Future<Product?> findProductExact(Product p) async {
    return findProduct(p.band, p.type, p.item,
        size: p.size, color: p.color, model: p.model, spec: p.spec);
  }

  static Future<List<Product>> searchProducts(String query) async {
    final db = _db;
    if (db == null) return [];
    final like = '%$query%';
    final results = await db.query('products',
      where: 'band LIKE ? OR type LIKE ? OR item LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'created_at DESC', limit: 50);
    return results.map(Product.fromMap).toList();
  }

  static Future<List<Product>> getAllProducts() async {
    final db = _db;
    if (db == null) return [];
    final results = await db.query('products', orderBy: 'created_at DESC');
    return results.map(Product.fromMap).toList();
  }

  // ── Stock ──

  static Future<int> getStock(int productId) async {
    final db = _db;
    if (db == null) return 0;
    final inResult = await db.rawQuery(
      'SELECT COALESCE(SUM(ti.qty),0) as total FROM transaction_items ti '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE ti.product_id = ? AND t.type = ?', [productId, 'IN']);
    final inQty = (inResult.first['total'] as int?) ?? 0;
    final outResult = await db.rawQuery(
      'SELECT COALESCE(SUM(ti.qty),0) as total FROM transaction_items ti '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE ti.product_id = ? AND t.type = ?', [productId, 'OUT']);
    final outQty = (outResult.first['total'] as int?) ?? 0;
    return inQty - outQty;
  }

  // ── IMEI Units ──

  static Future<void> insertImeiUnit(int productId, String scode, {int? inboundTxId}) async {
    final db = _db;
    if (db == null) return;
    await db.insert('imei_units', {
      'product_id': productId, 'scode': scode,
      'status': 'in_stock', 'inbound_tx_id': inboundTxId,
    });
  }

  static Future<ImeiUnit?> findImeiUnit(String scode) async {
    final db = _db;
    if (db == null) return null;
    final results = await db.query('imei_units',
      where: 'scode = ?', whereArgs: [scode], limit: 1);
    if (results.isEmpty) return null;
    return ImeiUnit.fromMap(results.first);
  }

  static Future<void> markImeiSoldOut(String scode, int outboundTxId) async {
    final db = _db;
    if (db == null) return;
    await db.update('imei_units',
      {'status': 'sold_out', 'outbound_tx_id': outboundTxId},
      where: 'scode = ?', whereArgs: [scode]);
  }

  // ── Price helpers ──

  static Future<double?> getLastInboundPrice(int productId) async {
    final db = _db;
    if (db == null) return null;
    final result = await db.rawQuery(
      'SELECT ti.unit_price FROM transaction_items ti '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE ti.product_id = ? AND t.type = ? '
      'ORDER BY t.created_at DESC LIMIT 1', [productId, 'IN']);
    if (result.isEmpty) return null;
    return (result.first['unit_price'] as num?)?.toDouble();
  }

  static Future<double?> getLastOutboundPrice(int productId) async {
    final db = _db;
    if (db == null) return null;
    final result = await db.rawQuery(
      'SELECT ti.unit_price FROM transaction_items ti '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE ti.product_id = ? AND t.type = ? '
      'ORDER BY t.created_at DESC LIMIT 1', [productId, 'OUT']);
    if (result.isEmpty) return null;
    return (result.first['unit_price'] as num?)?.toDouble();
  }

  static void _addNullableCondition(
    List<String> whereParts, List<dynamic> whereArgs,
    String column, String? value,
  ) {
    if (value != null) {
      whereParts.add('$column = ?');
      whereArgs.add(value);
    } else {
      whereParts.add('$column IS NULL');
    }
  }
}
