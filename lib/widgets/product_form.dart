import 'package:flutter/material.dart';
import 'package:warehouse/models/product.dart';

class ProductForm extends StatefulWidget {
  final String? prefillBarcode;
  const ProductForm({super.key, this.prefillBarcode});
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final _upcCtrl = TextEditingController(text: widget.prefillBarcode ?? '');
  late final _bandCtrl = TextEditingController();
  late final _typeCtrl = TextEditingController();
  late final _itemCtrl = TextEditingController();
  late final _sizeCtrl = TextEditingController();
  late final _colorCtrl = TextEditingController();
  late final _modelCtrl = TextEditingController();
  late final _specCtrl = TextEditingController();

  @override
  void dispose() {
    _upcCtrl.dispose(); _bandCtrl.dispose(); _typeCtrl.dispose();
    _itemCtrl.dispose(); _sizeCtrl.dispose(); _colorCtrl.dispose();
    _modelCtrl.dispose(); _specCtrl.dispose();
    super.dispose();
  }

  Product? _submit() {
    if (!_formKey.currentState!.validate()) return null;
    return Product(
      upc: _upcCtrl.text.trim(), band: _bandCtrl.text.trim(),
      type: _typeCtrl.text.trim(), item: _itemCtrl.text.trim(),
      size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      spec: _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _rf('UPC 條碼', _upcCtrl, '4901234567890'), const SizedBox(height: 10),
          _rf('BAND 品牌', _bandCtrl, 'Apple'), const SizedBox(height: 10),
          _rf('TYPE 類型', _typeCtrl, 'iPhone'), const SizedBox(height: 10),
          _rf('ITEM 品項', _itemCtrl, '17Pro Max'), const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _of('SIZE', _sizeCtrl)), const SizedBox(width: 10),
            Expanded(child: _of('COLOR', _colorCtrl)),
          ]), const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _of('MODEL', _modelCtrl)), const SizedBox(width: 10),
            Expanded(child: _of('SPEC', _specCtrl)),
          ]), const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () {
              final p = _submit();
              if (p != null) Navigator.pop(context, p);
            },
            child: const Text('建立商品'),
          )),
        ]),
      ),
    );
  }

  Widget _rf(String label, TextEditingController c, String hint) => TextFormField(
    controller: c, decoration: InputDecoration(labelText: '$label *', hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
  );

  Widget _of(String label, TextEditingController c) => TextField(
    controller: c, decoration: InputDecoration(labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
  );
}
