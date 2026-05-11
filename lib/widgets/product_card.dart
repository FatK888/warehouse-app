import 'package:flutter/material.dart';
import 'package:warehouse/models/product.dart';

/// 商品資訊卡片，用於列表展示。
class ProductCard extends StatelessWidget {
  final Product product;
  final int? stock;
  final double? inboundPrice;
  final double? outboundPrice;

  const ProductCard({
    super.key,
    required this.product,
    this.stock,
    this.inboundPrice,
    this.outboundPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.displayName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildField('BAND', product.band),
                const SizedBox(width: 12),
                _buildField('TYPE', product.type),
              ],
            ),
            Row(
              children: [
                _buildField('ITEM', product.item),
                const SizedBox(width: 12),
                if (product.size != null) _buildField('SIZE', product.size!),
              ],
            ),
            if (product.color != null || product.model != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (product.color != null) _buildField('COLOR', product.color!),
                  if (product.color != null && product.model != null) const SizedBox(width: 12),
                  if (product.model != null) _buildField('MODEL', product.model!),
                ],
              ),
            ],
            if (stock != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('庫存: ${stock!}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: stock! > 5 ? Colors.green : Colors.red)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Text('$label: $value', style: TextStyle(fontSize: 12, color: Colors.grey[600]));
  }
}
