import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📦', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('倉庫管理系統',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 4),
              Text('九龍灣主倉',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 32),
              _BigButton(
                icon: '📥',
                label: 'IN 入貨',
                subtitle: '掃描條碼 → 確認入庫',
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, '/inbound'),
              ),
              const SizedBox(height: 14),
              _BigButton(
                icon: '📤',
                label: 'OUT 出貨',
                subtitle: '掃描條碼 → 確認出庫',
                color: Colors.red,
                onTap: () => Navigator.pushNamed(context, '/outbound'),
              ),
              const SizedBox(height: 14),
              _BigButton(
                icon: '🔍',
                label: 'CHK 查詢',
                subtitle: '庫存查詢 / 商品搜尋 / 編輯',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/check'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
