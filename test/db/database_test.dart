import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:warehouse/db/database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('database should initialize and create all tables', () async {
    final db = await AppDatabase.initialize(databaseFactoryFfi);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );

    final tableNames = tables.map((r) => r['name']).toList();
    expect(tableNames, contains('products'));
    expect(tableNames, contains('imei_units'));
    expect(tableNames, contains('transactions'));
    expect(tableNames, contains('transaction_items'));

    final columns = await db.rawQuery("PRAGMA table_info('products')");
    final columnNames = columns.map((c) => c['name']).toList();
    expect(columnNames, contains('band'));
    expect(columnNames, contains('type'));
    expect(columnNames, contains('item'));

    await db.close();
  });
}
