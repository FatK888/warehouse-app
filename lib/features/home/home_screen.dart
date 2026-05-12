import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('倉庫管理'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 4),
                Text(auth.username, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(auth.isAdmin ? '(管理員)' : '(操作員)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  tooltip: '登出',
                  onPressed: () => auth.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📦', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
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
                subtitle: '庫存查詢 / 商品搜尋 / 編輯 / 單據',
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
