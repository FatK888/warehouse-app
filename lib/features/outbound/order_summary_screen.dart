import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/providers/batch_provider.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();
    final buyerName = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text('確認出庫')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.local_shipping, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('買家: $buyerName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('${provider.itemCount} 件商品',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('共 ${provider.totalQty} 單位',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('HK\$ ${provider.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
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
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _confirmOutbound(context, provider, buyerName),
                    child: const Text('確認出庫'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOutbound(
      BuildContext context, BatchProvider provider, String buyerName) async {
    final db = AppDatabase.db;

    await db.transaction((txn) async {
      final txId = await txn.insert('transactions', {
        'type': 'OUT',
        'buyer_name': buyerName,
        'total_qty': provider.totalQty,
        'total_amount': provider.totalAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in provider.items) {
        final existing = await Queries.findProductExact(item.product);
        if (existing == null || existing.id == null) continue;
        final productId = existing.id!;

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
          await txn.update(
            'imei_units',
            {'status': 'sold_out', 'outbound_tx_id': txId},
            where: 'scode = ? AND status = ?',
            whereArgs: [scode, 'in_stock'],
          );
        }
      }
    });

    if (!context.mounted) return;
    provider.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('出庫成功'), backgroundColor: Colors.green),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
