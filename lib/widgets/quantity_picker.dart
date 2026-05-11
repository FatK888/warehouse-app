import 'package:flutter/material.dart';

/// 數量加減器，支援 IMEI 掃描提示。
class QuantityPicker extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  final bool showImeiHint;

  const QuantityPicker({
    super.key,
    required this.qty,
    required this.onChanged,
    this.showImeiHint = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: qty > 1 ? () => onChanged(qty - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$qty',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.filled(
              onPressed: () => onChanged(qty + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (showImeiHint)
          Text(
            '或掃描 IMEI 自動 +1',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
      ],
    );
  }
}
