import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/providers/batch_provider.dart';
import 'package:warehouse/widgets/barcode_scanner.dart';
import 'package:warehouse/widgets/quantity_picker.dart';
import 'package:warehouse/widgets/product_card.dart';
import 'package:warehouse/widgets/product_form.dart';
import 'package:warehouse/widgets/batch_item_list.dart';

class InboundScreen extends StatefulWidget {
  const InboundScreen({super.key});

  @override
  State<InboundScreen> createState() => _InboundScreenState();
}

class _InboundScreenState extends State<InboundScreen> {
  Product? _currentProduct;
  int _qty = 1;
  double _unitPrice = 0.0;
  final List<String> _currentScodes = [];
  bool _showBatch = false;

  Future<void> _onScanned(String barcode) async {
    // 先 UPC 精準查 → SCODE → 文字搜索
    Product? product = await Queries.findProductByUpc(barcode);
    if (product == null) product = await Queries.findProductByScode(barcode);

    if (product == null) {
      final products = await Queries.searchProducts(barcode);
      if (products.isNotEmpty) {
        product = products.first;
      }
    }

    if (product == null) {
      if (!mounted) return;
      product = await showModalBottomSheet<Product>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ProductForm(prefillBarcode: barcode),
      );

      if (product != null) {
        final id = await Queries.insertProduct(product);
        product = product.copyWith(id: id);
      } else {
        return;
      }
    }

    setState(() {
      _currentProduct = product;
      _qty = 1;
      _unitPrice = 0.0;
      _currentScodes.clear();
    });
  }

  void _addToBatch() {
    if (_currentProduct == null) return;
    final provider = context.read<BatchProvider>();
    provider.addItem(
      _currentProduct!,
      qty: _qty,
      unitPrice: _unitPrice,
      scodes: _currentScodes.isNotEmpty ? List.from(_currentScodes) : null,
    );
    setState(() {
      _currentProduct = null;
      _qty = 1;
      _unitPrice = 0.0;
      _currentScodes.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已加入批次'), duration: Duration(seconds: 1)),
    );
  }

  void _onScodeScanned(String scode) {
    _currentScodes.add(scode);
    setState(() => _qty++);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    if (_showBatch) {
      return Scaffold(
        appBar: AppBar(title: const Text('IN 入貨 - 批次')),
        body: BatchItemList(
          provider: provider,
          onContinueScan: () => setState(() => _showBatch = false),
          onComplete: () => Navigator.pushNamed(context, '/inbound/summary'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('IN 入貨'),
        actions: [
          if (provider.items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _showBatch = true),
              child: Text('批次 (${provider.items.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_currentProduct == null) ...[
            BarcodeScannerWidget(onScanned: _onScanned),
          ] else ...[
            ProductCard(product: _currentProduct!),
            const SizedBox(height: 16),
            Text('數量', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            QuantityPicker(
              qty: _qty,
              onChanged: (v) => setState(() => _qty = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '掃描 IMEI (+1)',
                  prefixIcon: const Icon(Icons.qr_code, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    _onScodeScanned(v.trim());
                  }
                },
              ),
            ),
            if (_currentScodes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Wrap(
                  spacing: 6,
                  children: _currentScodes.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 10)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() {
                      _currentScodes.remove(s);
                      _qty--;
                    }),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '單價 HKD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) => _unitPrice = double.tryParse(v) ?? 0.0,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _unitPrice > 0 ? _addToBatch : null,
                  icon: const Icon(Icons.add),
                  label: const Text('加入批次'),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _currentProduct = null;
                _currentScodes.clear();
              }),
              child: const Text('取消，重新掃描'),
            ),
          ],
        ],
      ),
    );
  }
}
