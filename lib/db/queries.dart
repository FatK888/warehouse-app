import 'package:sqflite/sqflite.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/stock_item.dart';
import 'package:warehouse/models/user.dart';
import 'package:warehouse/models/invoice.dart';
import 'package:warehouse/models/supplier.dart';

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

  static Future<Product?> findProductByUpc(String upc) async {
    final db = _db;
    if (db == null) return null;
    final results = await db.query('products',
      where: 'upc = ?', whereArgs: [upc], limit: 1);
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  static Future<List<Product>> searchProducts(String query) async {
    final db = _db;
    if (db == null) return [];
    final like = '%$query%';
    final results = await db.query('products',
      where: 'upc LIKE ? OR band LIKE ? OR type LIKE ? OR item LIKE ?',
      whereArgs: [like, like, like, like],
      orderBy: 'created_at DESC', limit: 50);
    return results.map(Product.fromMap).toList();
  }

  static Future<List<Product>> getAllProducts() async {
    final db = _db;
    if (db == null) return [];
    final results = await db.query('products', orderBy: 'created_at DESC');
    return results.map(Product.fromMap).toList();
  }

  // ── Stock (unified) ──

  static Future<int> getStockCount(int productId) async {
    final db = _db;
    if (db == null) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM stock WHERE product_id = ? AND status = ?',
      [productId, 'in_stock']);
    return (result.first['c'] as int?) ?? 0;
  }

  static Future<void> insertStockItems(int productId, int qty, double unitPrice, {
    List<String>? scodes, int? inboundTxId, String? inboundAt,
  }) async {
    final db = _db;
    if (db == null) return;
    final at = inboundAt ?? _nowFormatted();
    for (int i = 0; i < qty; i++) {
      final scode = (scodes != null && i < scodes.length) ? scodes[i] : null;
      await db.insert('stock', {
        'product_id': productId,
        'scode': scode,
        'status': 'in_stock',
        'unit_price': unitPrice,
        'inbound_at': at,
        'inbound_tx_id': inboundTxId,
      });
    }
  }

  /// OUT: 有SCODE就精準出，冇就FIFO出最舊嗰批
  static Future<List<int>> markStockSoldOut(int productId, int qty, {
    List<String>? scodes, int? outboundTxId,
  }) async {
    final db = _db;
    if (db == null) return [];
    final outAt = _nowFormatted();
    final List<int> usedIds = [];

    if (scodes != null && scodes.isNotEmpty) {
      for (final scode in scodes) {
        final rows = await db.query('stock',
          where: 'product_id = ? AND scode = ? AND status = ?',
          whereArgs: [productId, scode, 'in_stock'], limit: 1);
        if (rows.isNotEmpty) {
          final id = rows.first['id'] as int;
          await db.update('stock',
            {'status': 'sold_out', 'outbound_at': outAt, 'outbound_tx_id': outboundTxId},
            where: 'id = ?', whereArgs: [id]);
          usedIds.add(id);
        }
      }
    } else {
      // FIFO: 最舊嘅 in_stock 先出
      final rows = await db.query('stock',
        where: 'product_id = ? AND status = ?',
        whereArgs: [productId, 'in_stock'],
        orderBy: 'inbound_at ASC', limit: qty);
      for (final row in rows) {
        final id = row['id'] as int;
        await db.update('stock',
          {'status': 'sold_out', 'outbound_at': outAt, 'outbound_tx_id': outboundTxId},
          where: 'id = ?', whereArgs: [id]);
        usedIds.add(id);
      }
    }
    return usedIds;
  }

  static Future<StockItem?> findStockByScode(String scode) async {
    final db = _db;
    if (db == null) return null;
    final results = await db.query('stock',
      where: 'scode = ?', whereArgs: [scode], orderBy: 'inbound_at DESC', limit: 1);
    if (results.isEmpty) return null;
    return StockItem.fromMap(results.first);
  }

  // Latest product catalog (recent 10)
  static Future<List<Product>> getRecentProducts({int limit = 10}) async {
    final db = _db;
    if (db == null) return [];
    final results = await db.query('products',
      orderBy: 'created_at DESC', limit: limit);
    return results.map(Product.fromMap).toList();
  }

  // Products with stock > 0 (recent 10, with stock count)
  static Future<List<Map<String, dynamic>>> getProductsWithStock({int limit = 10}) async {
    final db = _db;
    if (db == null) return [];
    final results = await db.rawQuery('''
      SELECT p.*, (SELECT COUNT(*) FROM stock s WHERE s.product_id = p.id AND s.status = 'in_stock') as stock_count
      FROM products p
      WHERE stock_count > 0
      ORDER BY p.created_at DESC
      LIMIT ?
    ''', [limit]);
    return results;
  }

  // ── Price helpers ──

  static Future<double?> getLastInboundPrice(int productId) async {
    final db = _db;
    if (db == null) return null;
    final result = await db.query('stock',
      where: 'product_id = ? AND status = ?',
      whereArgs: [productId, 'in_stock'],
      orderBy: 'inbound_at DESC', limit: 1);
    if (result.isEmpty) return null;
    return (result.first['unit_price'] as num?)?.toDouble();
  }

  static Future<double?> getLastOutboundPrice(int productId) async {
    final db = _db;
    if (db == null) return null;
    final result = await db.query('stock',
      where: 'product_id = ? AND status = ? AND outbound_at IS NOT NULL',
      whereArgs: [productId, 'sold_out'],
      orderBy: 'outbound_at DESC', limit: 1);
    if (result.isEmpty) return null;
    return (result.first['unit_price'] as num?)?.toDouble();
  }

  static String _nowFormatted() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
  }

  // ── Suppliers ──

  static Future<List<Supplier>> searchSuppliers(String query) async {
    final db = _db;
    if (db == null) return [];
    final like = '%$query%';
    final results = await db.query('suppliers',
      where: 'name LIKE ?', whereArgs: [like], orderBy: 'name', limit: 20);
    return results.map(Supplier.fromMap).toList();
  }

  static Future<Supplier?> findSupplierByName(String name) async {
    final db = _db;
    if (db == null) return null;
    final results = await db.query('suppliers',
      where: 'name = ?', whereArgs: [name], limit: 1);
    if (results.isEmpty) return null;
    return Supplier.fromMap(results.first);
  }

  static Future<int> insertSupplier(Supplier s) async {
    final db = _db;
    if (db == null) return -1;
    return db.insert('suppliers', s.toMap());
  }

  // ── Users ──

  static Future<User?> login(String username, String password) async {
    final db = _db;
    if (db == null) return null;
    final results = await db.query('users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password], limit: 1);
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  // ── Invoices ──

  static Future<int> getNextInvNo() async {
    final db = _db;
    if (db == null) return 100001;
    final result = await db.rawQuery('SELECT COALESCE(MAX(CAST(inv_no AS INTEGER)), 100000) as m FROM invoices');
    return ((result.first['m'] as int?) ?? 100000) + 1;
  }

  static Future<int> insertInvoice(Invoice invoice) async {
    final db = _db;
    if (db == null) return -1;
    return db.insert('invoices', invoice.toMap());
  }

  static Future<void> insertInvoiceItem(InvoiceItem item) async {
    final db = _db;
    if (db == null) return;
    await db.insert('invoice_items', item.toMap());
  }

  static Future<List<Invoice>> searchInvoices({String? query, String? type, int? userId, int limit = 50}) async {
    final db = _db;
    if (db == null) return [];
    if (query != null && query.isNotEmpty) {
      final like = '%$query%';
      // Search in remark (SCODEs), supplier name, and invoice items product_info
      final results = await db.rawQuery('''
        SELECT DISTINCT i.* FROM invoices i
        LEFT JOIN suppliers s ON i.supplier_id = s.id
        LEFT JOIN invoice_items ii ON ii.invoice_id = i.id
        WHERE i.remark LIKE ? OR s.name LIKE ? OR ii.product_info LIKE ?
        ORDER BY i.created_at DESC LIMIT ?
      ''', [like, like, like, limit]);
      return results.map(Invoice.fromMap).toList();
    }
    return _searchInvoicesSimple(type: type, userId: userId, limit: limit);
  }

  static Future<List<Invoice>> _searchInvoicesSimple({String? type, int? userId, int limit = 50}) async {
    final db = _db;
    if (db == null) return [];
    final where = <String>[];
    final args = <dynamic>[];
    if (type != null) { where.add('type = ?'); args.add(type); }
    if (userId != null) { where.add('user_id = ?'); args.add(userId); }
    final results = await db.query('invoices',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC', limit: limit);
    return results.map(Invoice.fromMap).toList();
  }

  static Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = _db;
    if (db == null) return [];
    final results = await db.query('invoice_items',
      where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return results.map(InvoiceItem.fromMap).toList();
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
