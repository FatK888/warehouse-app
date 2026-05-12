import 'package:flutter/material.dart';
import 'package:warehouse/db/database.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/stock_item.dart';
import 'package:warehouse/models/invoice.dart';
import 'package:warehouse/widgets/barcode_scanner.dart';
import 'package:warehouse/widgets/product_card.dart';

enum ChkMode { scan, invoice }

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  ChkMode _mode = ChkMode.scan;

  // Scan state
  dynamic _result;
  int? _stock;
  double? _inboundPrice;
  double? _outboundPrice;
  Map<String, dynamic>? _imeiResult;

  // Invoice state
  List<Invoice> _invoices = [];
  bool _loadingInvoices = false;
  final _invoiceSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _invoiceSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices({String? query}) async {
    setState(() => _loadingInvoices = true);
    _invoices = await Queries.searchInvoices(query: query);
    setState(() => _loadingInvoices = false);
  }

  Future<void> _searchInvoices(String q) async {
    await _loadInvoices(query: q.isEmpty ? null : q);
  }

  Future<void> _onScanned(String code) async {
    final stockItem = await Queries.findStockByScode(code);
    if (stockItem != null) {
      setState(() { _result = stockItem; _imeiResult = null; _stock = null; });
      _loadStockDetails(stockItem);
      return;
    }

    Product? product = await Queries.findProductByUpc(code);
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
    final stock = await Queries.getStockCount(product.id!);
    final inPrice = await Queries.getLastInboundPrice(product.id!);
    final outPrice = await Queries.getLastOutboundPrice(product.id!);
    setState(() {
      _result = product; _stock = stock;
      _inboundPrice = inPrice; _outboundPrice = outPrice;
      _imeiResult = null;
    });
  }

  Future<void> _loadStockDetails(StockItem item) async {
    final db = AppDatabase.db;
    Map<String, dynamic>? inboundInfo, outboundInfo;
    inboundInfo = {'time': item.inboundAt, 'price': item.unitPrice};
    if (item.status == 'sold_out' && item.outboundAt != null) {
      outboundInfo = {'time': item.outboundAt, 'price': item.unitPrice};
      if (item.outboundTxId != null) {
        final tx = await db.query('transactions', where: 'id = ?', whereArgs: [item.outboundTxId], limit: 1);
        if (tx.isNotEmpty) outboundInfo!['buyer'] = tx.first['buyer_name'];
      }
    }
    setState(() => _imeiResult = {'item': item, 'inbound': inboundInfo, 'outbound': outboundInfo});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == ChkMode.scan ? 'CHK 查詢' : 'INVOICE 記錄'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _mode = _mode == ChkMode.scan ? ChkMode.invoice : ChkMode.scan;
                if (_mode == ChkMode.invoice) _loadInvoices();
              });
            },
            child: Text(_mode == ChkMode.scan ? '📋 單據' : '🔍 掃描'),
          ),
        ],
      ),
      body: _mode == ChkMode.scan ? _buildScanMode() : _buildInvoiceMode(),
    );
  }

  Widget _buildScanMode() {
    return Column(
      children: [
        BarcodeScannerWidget(onScanned: _onScanned),
        Expanded(child: _buildScanResult()),
      ],
    );
  }

  Widget _buildScanResult() {
    if (_result == null) {
      return const Center(child: Text('掃描條碼或 IMEI 查詢', style: TextStyle(color: Colors.grey)));
    }
    if (_result is Product) {
      final product = _result as Product;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ProductCard(product: product, stock: _stock),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            _priceRow('📥 最後入庫價', _inboundPrice),
            const Divider(),
            _priceRow('📤 最後出庫價', _outboundPrice),
          ]))),
        ]),
      );
    }
    if (_imeiResult != null) {
      final item = _imeiResult!['item'] as StockItem;
      final inbound = _imeiResult!['inbound'] as Map<String, dynamic>?;
      final outbound = _imeiResult!['outbound'] as Map<String, dynamic>?;
      return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(color: Colors.purple.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📱 SCODE: ${item.scode ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('狀態: ${item.status == "in_stock" ? "在庫" : "已出庫"}',
                  style: TextStyle(color: item.status == 'in_stock' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            ],
          ))),
          if (inbound != null) ...[
            const SizedBox(height: 8),
            Card(color: Colors.green.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📥 入庫記錄', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('時間: ${inbound['time']}'),
                Text('價錢: HK\$ ${(inbound['price'] as num?)?.toStringAsFixed(0) ?? "-"}'),
              ],
            ))),
          ],
          if (outbound != null) ...[
            const SizedBox(height: 8),
            Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📤 出庫記錄', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text('時間: ${outbound['time']}'),
                Text('價錢: HK\$ ${(outbound['price'] as num?)?.toStringAsFixed(0) ?? "-"}'),
                if (outbound['buyer'] != null) Text('買家: ${outbound['buyer']}'),
              ],
            ))),
          ],
        ],
      ));
    }
    return const SizedBox.shrink();
  }

  Widget _buildInvoiceMode() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _invoiceSearchCtrl,
          onChanged: _searchInvoices,
          decoration: InputDecoration(
            hintText: '搜尋商戶名稱 / SCODE',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _invoiceSearchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear),
                    onPressed: () { _invoiceSearchCtrl.clear(); _searchInvoices(''); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
      ),
      Expanded(child: _buildInvoiceList()),
    ]);
  }

  Widget _buildInvoiceList() {
    if (_loadingInvoices) return const Center(child: CircularProgressIndicator());
    if (_invoices.isEmpty) return const Center(child: Text('暫無單據記錄', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final isIn = inv.type == 'IN';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIn ? Colors.green.shade50 : Colors.red.shade50,
              child: Text(isIn ? 'IN' : 'OUT',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isIn ? Colors.green : Colors.red, fontSize: 12)),
            ),
            title: Text('#${inv.invNo}  ${inv.type == "IN" ? "入庫" : "出貨"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${inv.createdAt}  ${inv.totalQty}件  HK\$${inv.totalAmount.toStringAsFixed(0)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInvoiceDetail(context, inv),
          ),
        );
      },
    );
  }

  Future<void> _showInvoiceDetail(BuildContext context, Invoice inv) async {
    final items = await Queries.getInvoiceItems(inv.id!);
    String supplierName = '';
    String operatorName = '';
    if (inv.supplierId != null) {
      final db = AppDatabase.db;
      final s = await db.query('suppliers', where: 'id = ?', whereArgs: [inv.supplierId], limit: 1);
      if (s.isNotEmpty) supplierName = s.first['name'] as String;
    }
    if (inv.userId != 0) {
      final db = AppDatabase.db;
      final u = await db.query('users', where: 'id = ?', whereArgs: [inv.userId], limit: 1);
      if (u.isNotEmpty) operatorName = u.first['username'] as String;
    }

    if (!context.mounted) return;
    final isIn = inv.type == 'IN';
    final title = supplierName.isNotEmpty ? supplierName : (isIn ? '入庫' : '出貨');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('#${inv.invNo}    ${inv.type}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (supplierName.isNotEmpty)
                Text(supplierName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(inv.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('${item.productInfo}  ${item.qty}  \$${item.unitPrice}', style: const TextStyle(fontSize: 12)),
              )),
              if (inv.remark != null && inv.remark!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Remark: ${inv.remark}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
              const Divider(),
              Text('總數: ${inv.totalQty}        總價: HK\$ ${inv.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (operatorName.isNotEmpty)
                Text(operatorName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
      ),
    );
  }

  Widget _priceRow(String label, double? price) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label),
      Text(price != null ? 'HK\$ ${price.toStringAsFixed(0)}' : '—', style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }
}
