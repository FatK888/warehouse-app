import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/providers/batch_provider.dart';

class BatchSummaryScreen extends StatelessWidget {
  const BatchSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('確認入庫')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.inventory_2, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('${provider.itemCount} 件商品',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('共 ${provider.totalQty} 單位',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('HK\$ ${provider.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Text('⚠️ IMEI 詳細資料不顯示在此畫面',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 24),
            ...provider.items.map((item) => ListTile(
                  title: Text(item.product.displayName),
                  subtitle: Text('數量: ${item.qty}  |  單價: \$${item.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text('\$${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('編輯'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _confirmInbound(context, provider),
                    child: const Text('確認入庫'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmInbound(BuildContext context, BatchProvider provider) async {
    final db = AppDatabase.db;
    final totalQty = provider.totalQty;
    final totalAmount = provider.totalAmount;

    await db.transaction((txn) async {
      final txId = await txn.insert('transactions', {
        'type': 'IN',
        'total_qty': totalQty,
        'total_amount': totalAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in provider.items) {
        int productId;
        final existing = await Queries.findProductExact(item.product);
        if (existing?.id != null) {
          productId = existing!.id!;
        } else {
          productId = await txn.insert('products', item.product.toMap());
        }

        await txn.insert('transaction_items', {
          'transaction_id': txId,
          'product_id': productId,
          'qty': item.qty,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
          'scode_list': item.scodes.isNotEmpty
              ? '[${item.scodes.map((s) => '"$s"').join(',')}]'
              : null,
        });

        for (final scode in item.scodes) {
          await txn.insert('imei_units', {
            'product_id': productId,
            'scode': scode,
            'status': 'in_stock',
            'inbound_tx_id': txId,
          });
        }
      }
    });

    if (!context.mounted) return;
    provider.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('入庫成功'), backgroundColor: Colors.green),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
