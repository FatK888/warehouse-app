import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/providers/batch_provider.dart';
import 'package:warehouse/widgets/barcode_scanner.dart';
import 'package:warehouse/widgets/quantity_picker.dart';
import 'package:warehouse/widgets/product_card.dart';
import 'package:warehouse/widgets/supplier_form.dart';
import 'package:warehouse/widgets/scode_input.dart';
import 'package:warehouse/models/supplier.dart';

class OutboundScreen extends StatefulWidget {
  const OutboundScreen({super.key});
  @override
  State<OutboundScreen> createState() => _OutboundScreenState();
}

class _OutboundScreenState extends State<OutboundScreen> {
  Product? _currentProduct;
  int _qty = 1;
  double _unitPrice = 0.0;
  final List<String> _currentScodes = [];
  bool _showBuyerForm = false;
  final _supplierCtrl = TextEditingController();
  List<Supplier> _supplierResults = [];
  List<Map<String, dynamic>> _stockPreview = [];
  String _searchText = '';

  @override
  void initState() { super.initState(); _loadStock(); }

  Future<void> _loadStock() async {
    final r = await Queries.getProductsWithStock();
    if (mounted) setState(() => _stockPreview = r);
  }

  List<Map<String, dynamic>> get _filteredStock {
    if (_searchText.isEmpty) return _stockPreview;
    final q = _searchText.toLowerCase();
    return _stockPreview.where((p) =>
      '${p['upc']} ${p['band']} ${p['type']} ${p['item']}'.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchSupplier(String q) async {
    if (q.isEmpty) { setState(() => _supplierResults = []); return; }
    final r = await Queries.searchSuppliers(q);
    if (mounted) setState(() => _supplierResults = r);
  }

  void _selectSupplier(Supplier s) {
    Navigator.pushNamed(context, '/outbound/summary', arguments: s.name);
  }

  Future<void> _addNewSupplier() async {
    final s = await showSupplierForm(context, prefillName: _supplierCtrl.text.trim());
    if (s != null && mounted) {
      Navigator.pushNamed(context, '/outbound/summary', arguments: s.name);
    }
  }

  Future<void> _onScanned(String barcode) async {
    Product? product = await Queries.findProductByUpc(barcode);
    if (product == null) {
      final products = await Queries.searchProducts(barcode);
      if (products.isNotEmpty) product = products.first;
    }
    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品不存在，請先入貨'), backgroundColor: Colors.red));
      return;
    }
    setState(() { _currentProduct = product; _searchText = barcode; _qty = 1; _unitPrice = 0.0; _currentScodes.clear(); });
  }

  void _addToBatch() {
    if (_currentProduct == null) return;
    context.read<BatchProvider>().addItem(_currentProduct!, qty: _qty, unitPrice: _unitPrice,
        scodes: _currentScodes.isNotEmpty ? List.from(_currentScodes) : null);
    setState(() { _currentProduct = null; _qty = 1; _unitPrice = 0.0; _currentScodes.clear(); });
  }

  void _goToBuyer() {
    _supplierCtrl.clear();
    setState(() => _showBuyerForm = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    if (_showBuyerForm) {
      return Scaffold(
        appBar: AppBar(title: const Text('OUT 出貨 - 選擇商戶')),
        body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text('批次: ${provider.itemCount}件  共${provider.totalQty}單位  HK\$${provider.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 16),
          TextField(
            controller: _supplierCtrl, autofocus: true, onChanged: _searchSupplier,
            decoration: InputDecoration(
              labelText: '商戶名稱',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _supplierCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.add_circle, color: Colors.red),
                      onPressed: _addNewSupplier) : null,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _supplierResults.isEmpty && _supplierCtrl.text.isNotEmpty
                ? Center(child: TextButton(onPressed: _addNewSupplier,
                    child: const Text('+ 新增商戶', style: TextStyle(color: Colors.red))))
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
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('OUT 出貨'), actions: [
        if (provider.items.isNotEmpty)
          TextButton(onPressed: _goToBuyer, child: Text('下一步 (${provider.items.length})')),
      ]),
      body: Column(children: [
        if (_currentProduct == null) ...[
          BarcodeScannerWidget(onScanned: _onScanned),
        ] else ...[
          ProductCard(product: _currentProduct!),
          const SizedBox(height: 16),
          Text('數量', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          QuantityPicker(qty: _qty, onChanged: (v) => setState(() => _qty = v), showImeiHint: false),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: '單價 HKD',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: (v) => setState(() => _unitPrice = double.tryParse(v) ?? 0.0),
          )),
          const SizedBox(height: 8),
          ScodeInput(
            scodes: _currentScodes,
            onAdd: (s) => setState(() => _currentScodes.add(s)),
            onRemove: (i) => setState(() => _currentScodes.removeAt(i)),
            hintText: '掃描/輸入 SCODE (IMEI)',
          ),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _unitPrice > 0 ? _addToBatch : null,
              icon: const Icon(Icons.add), label: const Text('加入出貨單'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ))),
        ],
      ]),
      bottomNavigationBar: SizedBox(height: 160, child: _buildStockPreview()),
    );
  }

  Widget _buildStockPreview() {
    final filtered = _filteredStock;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), color: Colors.grey.shade100,
        child: Row(children: [
          Text('📦 可出庫商品 (${filtered.length}筆)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          if (_searchText.isNotEmpty) ...[
            const Spacer(),
            TextButton(onPressed: () => setState(() => _searchText = ''), child: const Text('清除', style: TextStyle(fontSize: 11))),
          ],
        ])),
      Expanded(child: filtered.isEmpty
        ? const Center(child: Text('暫無庫存商品', style: TextStyle(color: Colors.grey, fontSize: 12)))
        : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: filtered.length,
            itemBuilder: (_, i) {
              final p = filtered[i]; final sc = p['stock_count'] as int;
              return ListTile(dense: true,
                leading: Text(p['upc'], style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                title: Text('${p['band']} ${p['type']} ${p['item']}', style: const TextStyle(fontSize: 12)),
                trailing: Text('庫存: $sc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: sc > 5 ? Colors.green : Colors.red)),
                onTap: () => _onScanned(p['upc'] as String),
              );
            })),
    ]);
  }
}
