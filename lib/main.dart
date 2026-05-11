import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppDatabase.initialize();
  } catch (_) {
    // DB not available (e.g. web) — app runs in preview mode
  }

  runApp(const WarehouseApp());
}
