import 'package:flutter/material.dart';

class ScodeInput extends StatefulWidget {
  final List<String> scodes;
  final Function(String) onAdd;
  final Function(int) onRemove;
  final String? hintText;

  const ScodeInput({
    super.key,
    required this.scodes,
    required this.onAdd,
    required this.onRemove,
    this.hintText,
  });

  @override
  State<ScodeInput> createState() => _ScodeInputState();
}

class _ScodeInputState extends State<ScodeInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      widget.onAdd(text);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '掃描/輸入 SCODE',
                    prefixIcon: const Icon(Icons.qr_code, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _submit,
                icon: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          if (widget.scodes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('已輸入: ${widget.scodes.length} 條 SCODE',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Wrap(
              spacing: 6, runSpacing: 2,
              children: List.generate(widget.scodes.length, (i) {
                return Chip(
                  label: Text(widget.scodes[i], style: const TextStyle(fontSize: 10)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => widget.onRemove(i),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
