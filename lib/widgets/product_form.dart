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
  late final TextEditingController _upcCtrl;
  late final TextEditingController _bandCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _itemCtrl;
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _scodeCtrl;

  @override
  void initState() {
    super.initState();
    _upcCtrl = TextEditingController(text: widget.prefillBarcode ?? '');
    _bandCtrl = TextEditingController();
    _typeCtrl = TextEditingController();
    _itemCtrl = TextEditingController();
    _sizeCtrl = TextEditingController();
    _colorCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _specCtrl = TextEditingController();
    _scodeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _upcCtrl.dispose();
    _bandCtrl.dispose();
    _typeCtrl.dispose();
    _itemCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _modelCtrl.dispose();
    _specCtrl.dispose();
    _scodeCtrl.dispose();
    super.dispose();
  }

  Product? _submit() {
    if (!_formKey.currentState!.validate()) return null;
    return Product(
      upc: _upcCtrl.text.trim(),
      band: _bandCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      item: _itemCtrl.text.trim(),
      size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      spec: _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
      scode: _scodeCtrl.text.trim().isEmpty ? null : _scodeCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRequiredField('UPC 條碼', _upcCtrl, '4901234567890'),
            const SizedBox(height: 10),
            _buildRequiredField('BAND 品牌', _bandCtrl, 'Apple'),
            const SizedBox(height: 10),
            _buildRequiredField('TYPE 類型', _typeCtrl, 'iPhone'),
            const SizedBox(height: 10),
            _buildRequiredField('ITEM 品項', _itemCtrl, '17Pro Max'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildOptionalField('SIZE', _sizeCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _buildOptionalField('COLOR', _colorCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildOptionalField('MODEL', _modelCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _buildOptionalField('SPEC', _specCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            _buildOptionalField('SCODE (IMEI)', _scodeCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final product = _submit();
                  if (product != null) Navigator.pop(context, product);
                },
                child: const Text('建立商品'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredField(String label, TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
    );
  }

  Widget _buildOptionalField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
