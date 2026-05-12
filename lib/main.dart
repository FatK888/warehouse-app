import 'package:flutter/material.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.initialize();
  runApp(const WarehouseApp());
}
