import 'dart:io' show File, Directory;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/invoice.dart';
import 'package:warehouse/providers/auth_provider.dart';
import 'package:warehouse/providers/batch_provider.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();
    final buyerName = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text('確認出庫')),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        const Icon(Icons.local_shipping, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text('買家: $buyerName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('${provider.itemCount} 件商品', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text('共 ${provider.totalQty} 單位', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('HK\$ ${provider.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 24),
        ...provider.items.map((item) => ListTile(
              title: Text(item.product.displayName),
              subtitle: Text('數量: ${item.qty}  |  單價: \$${item.unitPrice.toStringAsFixed(2)}'),
              trailing: Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
        const Spacer(),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('編輯'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _confirmOutbound(context, provider, buyerName),
            child: const Text('確認出庫'),
          )),
        ]),
      ])),
    );
  }

  Future<void> _confirmOutbound(BuildContext context, BatchProvider provider, String buyerName) async {
    try {
      final db = AppDatabase.db;
      final totalQty = provider.totalQty;
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id ?? 1;

      int txId = 0;
      await db.transaction((txn) async {
        txId = await txn.insert('transactions', {
          'type': 'OUT', 'buyer_name': buyerName,
          'total_qty': totalQty, 'total_amount': provider.totalAmount,
          'created_at': _nowFormatted(),
        });
        for (final item in provider.items) {
          final ex = await txn.query('products', where: 'upc = ?', whereArgs: [item.product.upc], limit: 1);
          if (ex.isEmpty) continue;
          final pid = ex.first['id'] as int;
          await txn.insert('transaction_items', {
            'transaction_id': txId, 'product_id': pid,
            'qty': item.qty, 'unit_price': item.unitPrice, 'subtotal': item.subtotal,
          });
        }
      });

      // Stock FIFO — link to transaction
      for (final item in provider.items) {
        final ex = await db.query('products', where: 'upc = ?', whereArgs: [item.product.upc], limit: 1);
        if (ex.isNotEmpty) {
          await Queries.markStockSoldOut(ex.first['id'] as int, item.qty, outboundTxId: txId);
        }
      }

      final allScodes = <String>[];
      for (final item in provider.items) {
        if (item.scodes.isNotEmpty) allScodes.addAll(item.scodes);
      }
      final remark = allScodes.isNotEmpty ? allScodes.join(', ') : null;

      // Invoice
      final invNo = await Queries.getNextInvNo();
      final now = _nowFormatted();
      final filename = 'OUT${now.replaceAll(RegExp(r'[\-\s:]'), '')}';
      final inv = Invoice(
        invNo: '$invNo', type: 'OUT', supplierId: null,
        userId: userId, totalQty: totalQty, totalAmount: provider.totalAmount,
        createdAt: now, filename: filename, remark: remark,
      );
      final invId = await Queries.insertInvoice(inv);
      for (final item in provider.items) {
        await Queries.insertInvoiceItem(InvoiceItem(
          invoiceId: invId, productInfo: item.product.fullDescription,
          qty: item.qty, unitPrice: item.unitPrice, subtotal: item.subtotal,
        ));
      }

      await _saveFile(filename, inv, provider.items, auth.username, buyerName, remark);

      if (!context.mounted) return;
      provider.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${totalQty}件商品成功出庫  INVNO:$invNo'),
        backgroundColor: Colors.green, duration: const Duration(seconds: 2)));
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('出庫失敗'), content: Text('$e'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ));
    }
  }

  Future<void> _saveFile(String filename, Invoice inv, items, String username, String buyer, String? remark) async {
    try {
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/invoices');
      if (!await dir.exists()) await dir.create(recursive: true);
      final f = File('${dir.path}/$filename.txt');
      final b = StringBuffer();
      b.writeln('#${inv.invNo}    OUT');
      b.writeln(buyer);
      b.writeln(inv.createdAt);
      for (final item in items) {
        b.writeln('${item.product.fullDescription}  ${item.qty}  \$${item.unitPrice}');
      }
      if (remark != null && remark.isNotEmpty) b.writeln('Remark: $remark');
      b.writeln('總數: ${inv.totalQty}        總價: HK\$ ${inv.totalAmount.toStringAsFixed(0)}');
      b.writeln(username);
      await f.writeAsString(b.toString());
    } catch (_) {}
  }

  String _nowFormatted() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
  }
}
