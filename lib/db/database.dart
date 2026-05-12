import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _dbName = 'warehouse.db';
  static const int _version = 1;
  static Database? _instance;
  static bool initialized = false;

  static Future<Database> initialize([DatabaseFactory? factory]) async {
    if (_instance != null) return _instance!;

    final dbFactory = factory ?? databaseFactory;
    final dbPath = await dbFactory.getDatabasesPath();
    final path = join(dbPath, _dbName);

    _instance = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
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
        scode      TEXT,
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
  }
}
