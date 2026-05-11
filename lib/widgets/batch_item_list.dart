import 'package:flutter/material.dart';
import 'package:warehouse/providers/batch_provider.dart';

/// 批次商品列表，顯示已掃描的商品，支援繼續掃描 / 完成操作。
class BatchItemList extends StatelessWidget {
  final BatchProvider provider;
  final VoidCallback onContinueScan;
  final VoidCallback onComplete;

  const BatchItemList({
    super.key,
    required this.provider,
    required this.onContinueScan,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: provider.items.isEmpty
              ? const Center(child: Text('尚未掃描商品'))
              : ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(item.product.displayName),
                        subtitle: Text('數量: ${item.qty}  |  單價: \$${item.unitPrice.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => provider.removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinueScan,
                  child: const Text('繼續掃描'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: provider.items.isEmpty ? null : onComplete,
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
