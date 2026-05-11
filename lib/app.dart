import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/providers/batch_provider.dart';
import 'package:warehouse/features/home/home_screen.dart';
import 'package:warehouse/features/inbound/inbound_screen.dart';
import 'package:warehouse/features/inbound/batch_summary_screen.dart';
import 'package:warehouse/features/outbound/outbound_screen.dart';
import 'package:warehouse/features/outbound/order_summary_screen.dart';
import 'package:warehouse/features/check/check_screen.dart';

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BatchProvider()),
      ],
      child: MaterialApp(
        title: '倉庫管理',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/inbound': (_) => const InboundScreen(),
          '/inbound/summary': (_) => const BatchSummaryScreen(),
          '/outbound': (_) => const OutboundScreen(),
          '/outbound/summary': (_) => const OrderSummaryScreen(),
          '/check': (_) => const CheckScreen(),
        },
      ),
    );
  }
}
