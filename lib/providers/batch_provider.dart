import 'package:flutter/foundation.dart';
import 'package:warehouse/models/product.dart';
import 'package:warehouse/models/transaction_item.dart';

class BatchProvider extends ChangeNotifier {
  final List<BatchItem> _items = [];

  List<BatchItem> get items => List.unmodifiable(_items);

  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get itemCount => _items.length;

  void addItem(Product product,
      {int qty = 1, double unitPrice = 0.0, List<String>? scodes}) {
    _items.add(BatchItem(
      product: product,
      qty: qty,
      unitPrice: unitPrice,
      scodes: scodes,
    ));
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateQty(int index, int newQty) {
    if (index >= 0 && index < _items.length && newQty > 0) {
      _items[index].qty = newQty;
      notifyListeners();
    }
  }

  void updatePrice(int index, double newPrice) {
    if (index >= 0 && index < _items.length) {
      _items[index].unitPrice = newPrice;
      notifyListeners();
    }
  }

  void addScodeToItem(int index, String scode) {
    if (index >= 0 && index < _items.length) {
      _items[index].addScode(scode);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
