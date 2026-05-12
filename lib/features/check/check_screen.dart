import 'package:flutter/material.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/imei_unit.dart';
import 'package:warehouse/widgets/barcode_scanner.dart';
import 'package:warehouse/widgets/product_card.dart';

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  dynamic _result;
  int? _stock;
  double? _inboundPrice;
  double? _outboundPrice;
  Map<String, dynamic>? _imeiResult;

  Future<void> _onScanned(String code) async {
    // 先試 IMEI 查詢
    final imeiUnit = await Queries.findImeiUnit(code);

    if (imeiUnit != null) {
      setState(() {
        _result = imeiUnit;
        _imeiResult = null;
        _stock = null;
      });
      _loadImeiDetails(imeiUnit);
      return;
    }

    // 商品查詢 — 先 UPC → SCODE → 文字搜索
    Product? product = await Queries.findProductByUpc(code);
    if (product == null) product = await Queries.findProductByScode(code);

    if (product == null) {
      final products = await Queries.searchProducts(code);
      if (products.isNotEmpty) product = products.first;
    }

    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('搵唔到相關商品或 IMEI'), backgroundColor: Colors.orange),
      );
      return;
    }
    final stock = await Queries.getStock(product.id!);
    final inPrice = await Queries.getLastInboundPrice(product.id!);
    final outPrice = await Queries.getLastOutboundPrice(product.id!);

    setState(() {
      _result = product;
      _stock = stock;
      _inboundPrice = inPrice;
      _outboundPrice = outPrice;
      _imeiResult = null;
    });
  }

  Future<void> _loadImeiDetails(ImeiUnit unit) async {
    final db = AppDatabase.db;

    Map<String, dynamic>? inboundInfo;
    Map<String, dynamic>? outboundInfo;

    if (unit.inboundTxId != null) {
      final inResults = await db.query('transactions',
          where: 'id = ?', whereArgs: [unit.inboundTxId]);
      if (inResults.isNotEmpty) {
        final tx = inResults.first;
        final items = await db.query('transaction_items',
            where: 'transaction_id = ? AND product_id = ?',
            whereArgs: [unit.inboundTxId, unit.productId]);
        final price = items.isNotEmpty ? items.first['unit_price'] : null;
        inboundInfo = {
          'time': tx['created_at'],
          'price': price,
        };
      }
    }

    if (unit.outboundTxId != null) {
      final outResults = await db.query('transactions',
          where: 'id = ?', whereArgs: [unit.outboundTxId]);
      if (outResults.isNotEmpty) {
        final tx = outResults.first;
        final items = await db.query('transaction_items',
            where: 'transaction_id = ? AND product_id = ?',
            whereArgs: [unit.outboundTxId, unit.productId]);
        final price = items.isNotEmpty ? items.first['unit_price'] : null;
        outboundInfo = {
          'time': tx['created_at'],
          'price': price,
          'buyer': tx['buyer_name'],
        };
      }
    }

    setState(() {
      _imeiResult = {
        'unit': unit,
        'inbound': inboundInfo,
        'outbound': outboundInfo,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHK 查詢')),
      body: Column(
        children: [
          BarcodeScannerWidget(onScanned: _onScanned),
          Expanded(child: _buildResult()),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) {
      return const Center(
        child: Text('掃描條碼或 IMEI 查詢',
            style: TextStyle(color: Colors.grey)),
      );
    }

    if (_result is Product) {
      final product = _result as Product;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProductCard(
              product: product,
              stock: _stock,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _priceRow('📥 最後入庫價', _inboundPrice),
                    const Divider(),
                    _priceRow('📤 最後出庫價', _outboundPrice),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_imeiResult != null) {
      final unit = _imeiResult!['unit'] as ImeiUnit;
      final inbound = _imeiResult!['inbound'] as Map<String, dynamic>?;
      final outbound = _imeiResult!['outbound'] as Map<String, dynamic>?;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📱 IMEI: ${unit.scode}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('狀態: ${unit.status == "in_stock" ? "在庫" : "已出庫"}',
                        style: TextStyle(
                            color: unit.status == 'in_stock'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (inbound != null) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📥 入庫記錄',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      Text('時間: ${inbound['time']}'),
                      Text('價錢: HK\$ ${(inbound['price'] as num?)?.toStringAsFixed(0) ?? "-"}'),
                    ],
                  ),
                ),
              ),
            ],
            if (outbound != null) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📤 出庫記錄',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text('時間: ${outbound['time']}'),
                      Text('價錢: HK\$ ${(outbound['price'] as num?)?.toStringAsFixed(0) ?? "-"}'),
                      if (outbound['buyer'] != null)
                        Text('買家: ${outbound['buyer']}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _priceRow(String label, double? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(price != null ? 'HK\$ ${price.toStringAsFixed(0)}' : '—',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
