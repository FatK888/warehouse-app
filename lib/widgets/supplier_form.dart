import 'package:flutter/material.dart';
import 'package:warehouse/db/queries.dart';
import 'package:warehouse/models/supplier.dart';

Future<Supplier?> showSupplierForm(BuildContext context, {String? prefillName}) {
  final nameCtrl = TextEditingController(text: prefillName ?? '');
  final addrCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final staffCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<Supplier>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('新增商戶'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl, autofocus: true,
              decoration: InputDecoration(labelText: '商戶名稱 *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 10),
            TextField(controller: addrCtrl,
              decoration: InputDecoration(labelText: '地址',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 10),
            TextField(controller: telCtrl, keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: '電話',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 10),
            TextField(controller: staffCtrl,
              decoration: InputDecoration(labelText: '員工',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final s = Supplier(
            name: nameCtrl.text.trim(),
            address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
            tel: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
            staff: staffCtrl.text.trim().isEmpty ? null : staffCtrl.text.trim(),
          );
          final id = await Queries.insertSupplier(s);
          if (ctx.mounted) Navigator.pop(ctx, s.copyWith(id: id));
        }, child: const Text('建立')),
      ],
    ),
  );
}
