import 'package:flutter/material.dart';
import 'package:warehouse/utils/platform.dart';

/// 條碼掃描 Widget — 桌面端顯示輸入框，手機端預留相機掃描接口。
class BarcodeScannerWidget extends StatelessWidget {
  final Function(String) onScanned;
  final String hintText;

  const BarcodeScannerWidget({
    super.key,
    required this.onScanned,
    this.hintText = '掃描或輸入條碼/IMEI',
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _MobileScannerView(onScanned: onScanned);
    } else {
      return _DesktopInputView(onScanned: onScanned, hintText: hintText);
    }
  }
}

/// 桌面端：純文字輸入框（模擬條碼槍）。
class _DesktopInputView extends StatelessWidget {
  final Function(String) onScanned;
  final String hintText;

  const _DesktopInputView({required this.onScanned, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.qr_code_scanner),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onScanned(text);
                controller.clear();
              }
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (value) {
          final text = value.trim();
          if (text.isNotEmpty) {
            onScanned(text);
            controller.clear();
          }
        },
        autofocus: true,
      ),
    );
  }
}

/// 手機端：預留相機掃描接口，目前先 fallback 到文字輸入。
class _MobileScannerView extends StatelessWidget {
  final Function(String) onScanned;

  const _MobileScannerView({required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return _DesktopInputView(
      onScanned: onScanned,
      hintText: '掃描或輸入條碼/IMEI',
    );
  }
}
