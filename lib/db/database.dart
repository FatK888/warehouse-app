import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _dbName = 'warehouse.db';
  static const int _version = 4;
  static Database? _instance;
  static bool initialized = false;

  static Future<Database> initialize([DatabaseFactory? factory]) async {
    if (_instance != null) return _instance!;

    DatabaseFactory dbFactory;
    if (factory != null) {
      dbFactory = factory;
    } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      dbFactory = databaseFactoryFfi;
    } else {
      dbFactory = databaseFactory;
    }

    final dbPath = await dbFactory.getDatabasesPath();
    final path = join(dbPath, _dbName);

    _instance = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    initialized = true;
    return _instance!;
  }

  static Database get db {
    if (_instance == null) throw StateError('Database not initialized');
    return _instance!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultUser(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id      INTEGER PRIMARY KEY AUTOINCREMENT,
          name    TEXT NOT NULL,
          address TEXT,
          tel     TEXT,
          staff   TEXT
        )
      ''');
      // Add supplier_id and remark to invoices if not exist
      try { await db.execute('ALTER TABLE invoices ADD COLUMN supplier_id INTEGER REFERENCES suppliers(id)'); } catch (_) {}
      try { await db.execute('ALTER TABLE invoices ADD COLUMN remark TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id     INTEGER NOT NULL REFERENCES products(id),
          scode          TEXT,
          status         TEXT NOT NULL DEFAULT 'in_stock' CHECK(status IN ('in_stock','sold_out')),
          unit_price     REAL,
          inbound_at     TEXT NOT NULL,
          outbound_at    TEXT,
          inbound_tx_id  INTEGER REFERENCES transactions(id),
          outbound_tx_id INTEGER REFERENCES transactions(id)
        )
      ''');
      // Migrate existing imei_units to stock
      final imeiRows = await db.query('imei_units');
      for (final row in imeiRows) {
        await db.insert('stock', {
          'product_id': row['product_id'],
          'scode': row['scode'],
          'status': row['status'],
          'inbound_tx_id': row['inbound_tx_id'],
          'outbound_tx_id': row['outbound_tx_id'],
          'inbound_at': '2026-01-01 00:00:00',
        });
      }
    }
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          username   TEXT NOT NULL UNIQUE,
          password   TEXT NOT NULL,
          permission TEXT NOT NULL DEFAULT 'operator' CHECK(permission IN ('admin','operator'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invoices (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          inv_no     TEXT NOT NULL UNIQUE,
          type       TEXT NOT NULL CHECK(type IN ('IN','OUT')),
          user_id    INTEGER NOT NULL REFERENCES users(id),
          total_qty  INTEGER NOT NULL,
          total_amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          filename   TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invoice_items (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_id INTEGER NOT NULL REFERENCES invoices(id),
          product_info TEXT NOT NULL,
          qty        INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          subtotal   REAL NOT NULL
        )
      ''');
      await _insertDefaultUser(db);
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        upc        TEXT NOT NULL,
        band       TEXT NOT NULL,
        type       TEXT NOT NULL,
        item       TEXT NOT NULL,
        size       TEXT,
        color      TEXT,
        model      TEXT,
        spec       TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
        UNIQUE(upc, band, type, item, size, color, model, spec)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        type          TEXT NOT NULL CHECK(type IN ('IN','OUT')),
        buyer_name    TEXT,
        buyer_contact TEXT,
        buyer_phone   TEXT,
        buyer_remark  TEXT,
        total_qty     INTEGER NOT NULL,
        total_amount  REAL NOT NULL,
        created_at    TEXT NOT NULL DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL REFERENCES transactions(id),
        product_id     INTEGER NOT NULL REFERENCES products(id),
        qty            INTEGER NOT NULL,
        unit_price     REAL NOT NULL,
        subtotal       REAL NOT NULL,
        scode_list     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE imei_units (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id     INTEGER NOT NULL REFERENCES products(id),
        scode          TEXT NOT NULL UNIQUE,
        status         TEXT NOT NULL DEFAULT 'in_stock'
                       CHECK(status IN ('in_stock','sold_out')),
        inbound_tx_id  INTEGER REFERENCES transactions(id),
        outbound_tx_id INTEGER REFERENCES transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id     INTEGER NOT NULL REFERENCES products(id),
        scode          TEXT,
        status         TEXT NOT NULL DEFAULT 'in_stock' CHECK(status IN ('in_stock','sold_out')),
        unit_price     REAL,
        inbound_at     TEXT NOT NULL,
        outbound_at    TEXT,
        inbound_tx_id  INTEGER REFERENCES transactions(id),
        outbound_tx_id INTEGER REFERENCES transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        username   TEXT NOT NULL UNIQUE,
        password   TEXT NOT NULL,
        permission TEXT NOT NULL DEFAULT 'operator' CHECK(permission IN ('admin','operator'))
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        address TEXT,
        tel     TEXT,
        staff   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        inv_no      TEXT NOT NULL UNIQUE,
        type        TEXT NOT NULL CHECK(type IN ('IN','OUT')),
        supplier_id INTEGER REFERENCES suppliers(id),
        user_id     INTEGER NOT NULL REFERENCES users(id),
        total_qty   INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        remark      TEXT,
        created_at  TEXT NOT NULL,
        filename    TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL REFERENCES invoices(id),
        product_info TEXT NOT NULL,
        qty        INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        subtotal   REAL NOT NULL
      )
    ''');
  }

  static Future<void> _insertDefaultUser(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) as c FROM users');
    if ((count.first['c'] as int) == 0) {
      await db.insert('users', {
        'username': 'admin',
        'password': '1234',
        'permission': 'admin',
      });
    }
  }
}
