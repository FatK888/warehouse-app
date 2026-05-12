import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/supplier.dart';
import 'package:warehouse/providers/batch_provider.dart';
import 'package:warehouse/widgets/barcode_scanner.dart';
import 'package:warehouse/widgets/quantity_picker.dart';
import 'package:warehouse/widgets/product_card.dart';
import 'package:warehouse/widgets/product_form.dart';
import 'package:warehouse/widgets/batch_item_list.dart';
import 'package:warehouse/widgets/supplier_form.dart';
import 'package:warehouse/widgets/scode_input.dart';

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
  bool _showSupplier = false;

  // Supplier search
  final _supplierCtrl = TextEditingController();
  List<Supplier> _supplierResults = [];

  // Preview
  List<Product> _previewProducts = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final p = await Queries.getRecentProducts();
    if (mounted) setState(() => _previewProducts = p);
  }

  List<Product> get _filteredPreview {
    if (_searchText.isEmpty) return _previewProducts;
    final q = _searchText.toLowerCase();
    return _previewProducts.where((p) =>
      p.upc.toLowerCase().contains(q) || p.band.toLowerCase().contains(q) ||
      p.type.toLowerCase().contains(q) || p.item.toLowerCase().contains(q)).toList();
  }

  Future<void> _onScanned(String barcode) async {
    Product? product = await Queries.findProductByUpc(barcode);
    if (product == null) {
      final products = await Queries.searchProducts(barcode);
      if (products.isNotEmpty) product = products.first;
    }
    if (product == null) {
      if (!mounted) return;
      product = await showModalBottomSheet<Product>(
        context: context, isScrollControlled: true,
        builder: (_) => ProductForm(prefillBarcode: barcode),
      );
      if (product != null) {
        final id = await Queries.insertProduct(product);
        product = product.copyWith(id: id);
      } else { return; }
    }
    setState(() { _currentProduct = product; _searchText = barcode; _qty = 1; _unitPrice = 0.0; _currentScodes.clear(); });
  }

  void _addToBatch() {
    if (_currentProduct == null) return;
    context.read<BatchProvider>().addItem(_currentProduct!, qty: _qty, unitPrice: _unitPrice,
        scodes: _currentScodes.isNotEmpty ? List.from(_currentScodes) : null);
    setState(() { _currentProduct = null; _qty = 1; _unitPrice = 0.0; _currentScodes.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已加入批次'), duration: Duration(seconds: 1)));
  }

  void _goToSupplier() => setState(() { _showBatch = false; _showSupplier = true; _supplierCtrl.clear(); _supplierResults = []; });

  Future<void> _searchSupplier(String q) async {
    if (q.isEmpty) { setState(() => _supplierResults = []); return; }
    final r = await Queries.searchSuppliers(q);
    if (mounted) setState(() => _supplierResults = r);
  }

  Future<void> _selectSupplier(Supplier s) async {
    Navigator.pushNamed(context, '/inbound/summary', arguments: s);
  }

  Future<void> _addNewSupplier() async {
    final s = await showSupplierForm(context, prefillName: _supplierCtrl.text.trim());
    if (s != null && mounted) {
      Navigator.pushNamed(context, '/inbound/summary', arguments: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    // Batch view
    if (_showBatch) {
      return Scaffold(
        appBar: AppBar(title: const Text('IN 入貨 - 批次')),
        body: BatchItemList(provider: provider,
          onContinueScan: () => setState(() => _showBatch = false),
          onComplete: _goToSupplier),
      );
    }

    // Supplier selection
    if (_showSupplier) {
      return Scaffold(
        appBar: AppBar(title: const Text('IN 入貨 - 選擇商戶')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text('批次: ${provider.itemCount}件  共${provider.totalQty}單位  HK\$${provider.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: _supplierCtrl,
              autofocus: true,
              onChanged: _searchSupplier,
              decoration: InputDecoration(
                labelText: '商戶名稱 *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _supplierCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: _addNewSupplier)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _supplierResults.isEmpty && _supplierCtrl.text.isNotEmpty
                  ? Center(child: TextButton(onPressed: _addNewSupplier,
                      child: const Text('+ 新增商戶')))
                  : ListView.builder(
                      itemCount: _supplierResults.length,
                      itemBuilder: (_, i) {
                        final s = _supplierResults[i];
                        return ListTile(
                          leading: const Icon(Icons.business),
                          title: Text(s.name),
                          subtitle: Text('${s.tel ?? ""} ${s.address ?? ""}'.trim(),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          onTap: () => _selectSupplier(s),
                        );
                      }),
            ),
          ]),
        ),
      );
    }

    // Main scan screen
    return Scaffold(
      appBar: AppBar(
        title: const Text('IN 入貨'),
        actions: [
          if (provider.items.isNotEmpty)
            TextButton(onPressed: () => setState(() => _showBatch = true),
                child: Text('批次 (${provider.items.length})')),
        ],
      ),
      body: Column(children: [
        if (_currentProduct == null) ...[
          BarcodeScannerWidget(onScanned: _onScanned),
        ] else ...[
          ProductCard(product: _currentProduct!),
          const SizedBox(height: 16),
          Text('數量', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          QuantityPicker(qty: _qty, onChanged: (v) => setState(() => _qty = v), showImeiHint: false),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '單價 HKD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              onChanged: (v) => setState(() => _unitPrice = double.tryParse(v) ?? 0.0),
            ),
          ),
          const SizedBox(height: 8),
          ScodeInput(
            scodes: _currentScodes,
            onAdd: (s) => setState(() => _currentScodes.add(s)),
            onRemove: (i) => setState(() => _currentScodes.removeAt(i)),
            hintText: '掃描/輸入 SCODE (IMEI)',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(width: double.infinity,
              child: FilledButton.icon(
                onPressed: _unitPrice > 0 ? _addToBatch : null,
                icon: const Icon(Icons.add), label: const Text('加入批次'),
              ),
            ),
          ),
          TextButton(onPressed: () => setState(() { _currentProduct = null; }),
              child: const Text('取消，重新掃描')),
        ],
      ]),
      bottomNavigationBar: SizedBox(height: 160, child: _buildPreview()),
    );
  }

  Widget _buildPreview() {
    final filtered = _filteredPreview;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), color: Colors.grey.shade100,
        child: Row(children: [
          Text('📋 商品目錄 (${filtered.length}筆)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          if (_searchText.isNotEmpty) ...[
            const Spacer(),
            TextButton(onPressed: () => setState(() => _searchText = ''), child: const Text('清除', style: TextStyle(fontSize: 11))),
          ],
        ])),
      Expanded(child: filtered.isEmpty
        ? const Center(child: Text('暫無商品', style: TextStyle(color: Colors.grey, fontSize: 12)))
        : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: filtered.length,
            itemBuilder: (_, i) {
              final p = filtered[i];
              return ListTile(dense: true,
                leading: Text(p.upc, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                title: Text(p.displayName, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                onTap: () => _onScanned(p.upc),
              );
            })),
    ]);
  }
}
