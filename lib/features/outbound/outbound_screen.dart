import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/providers/batch_provider.dart';
import 'package:warehouse/widgets/barcode_scanner.dart';
import 'package:warehouse/widgets/quantity_picker.dart';
import 'package:warehouse/widgets/product_card.dart';
import 'package:warehouse/widgets/batch_item_list.dart';

class OutboundScreen extends StatefulWidget {
  const OutboundScreen({super.key});

  @override
  State<OutboundScreen> createState() => _OutboundScreenState();
}

class _OutboundScreenState extends State<OutboundScreen> {
  final _buyerNameCtrl = TextEditingController();
  final _buyerContactCtrl = TextEditingController();
  final _buyerPhoneCtrl = TextEditingController();
  final _buyerRemarkCtrl = TextEditingController();

  Product? _currentProduct;
  int _qty = 1;
  double _unitPrice = 0.0;
  final List<String> _currentScodes = [];
  bool _showBuyerForm = true;
  bool _showBatch = false;

  @override
  void dispose() {
    _buyerNameCtrl.dispose();
    _buyerContactCtrl.dispose();
    _buyerPhoneCtrl.dispose();
    _buyerRemarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _onScanned(String barcode) async {
    // 先用 SCODE 精準查
    Product? product = await Queries.findProductByScode(barcode);

    // 搵唔到就文字搜索
    if (product == null) {
      final products = await Queries.searchProducts(barcode);
      if (products.isNotEmpty) product = products.first;
    }

    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品不存在，請先入貨'), backgroundColor: Colors.red),
      );
      return;
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
  }

  void _onScodeScanned(String scode) {
    _currentScodes.add(scode);
    setState(() => _qty++);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    if (_showBuyerForm) {
      return Scaffold(
        appBar: AppBar(title: const Text('OUT 出貨 - 買家資料')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _buyerNameCtrl,
                decoration: InputDecoration(
                  labelText: '公司/店舖名稱 *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buyerContactCtrl,
                decoration: InputDecoration(
                  labelText: '聯絡人',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buyerPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '電話',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buyerRemarkCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '備註',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _buyerNameCtrl.text.trim().isNotEmpty
                      ? () => setState(() => _showBuyerForm = false)
                      : null,
                  child: const Text('下一步 → 掃碼揀貨'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showBatch) {
      return Scaffold(
        appBar: AppBar(title: const Text('OUT 出貨 - 批次')),
        body: BatchItemList(
          provider: provider,
          onContinueScan: () => setState(() => _showBatch = false),
          onComplete: () => Navigator.pushNamed(context, '/outbound/summary',
              arguments: _buyerNameCtrl.text.trim()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OUT 出貨'),
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
                  if (v.trim().isNotEmpty) _onScodeScanned(v.trim());
                },
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
                  label: const Text('加入出貨單'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
