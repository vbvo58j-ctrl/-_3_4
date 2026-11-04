import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/blousab_visuals.dart';

/// In-app local notification history. The list contains only observed incoming
/// events, never sample/fabricated notifications or message plaintext.
class BlousabNotificationsScreen extends StatefulWidget {
  const BlousabNotificationsScreen({super.key});
  @override
  State<BlousabNotificationsScreen> createState() => _BlousabNotificationsScreenState();
}

class _BlousabNotificationsScreenState extends State<BlousabNotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList('blousab_notifications_v1') ?? [];
    final loaded = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        final json = jsonDecode(row);
        if (json is Map) loaded.add(Map<String, dynamic>.from(json));
      } catch (_) {}
    }
    if (mounted) setState(() { _items = loaded; _loading = false; });
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('مسح سجل الإشعارات؟'),
      content: const Text('سيُمسح سجل الإشعارات المحلي فقط؛ ستبقى الرسائل والمحادثات محفوظة.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('مسح السجل')),
      ],
    ));
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('blousab_notifications_v1');
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('الإشعارات'),
      actions: [
        IconButton(tooltip: 'تحديث', onPressed: _refresh, icon: const Icon(Icons.refresh, size: 21)),
        IconButton(tooltip: 'مسح السجل', onPressed: _items.isEmpty ? null : _clear, icon: const Icon(Icons.delete_outline, size: 21)),
      ],
    ),
    body: _loading ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(25), child: BlousabNeonPanel(
              padding: const EdgeInsets.all(25),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none_outlined, size: 48, color: BlousabVisuals.cyan),
                SizedBox(height: 12), Text('لا توجد إشعارات محلية بعد', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 7), Text('ستظهر هنا الرسائل الواردة التي رصدها التطبيق أثناء تشغيله.', textAlign: TextAlign.center),
              ]),
            )))
          : RefreshIndicator(onRefresh: _refresh, child: ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _items.length,
              itemBuilder: (ctx, index) {
                final item = _items[index];
                final sender = item['sender']?.toString() ?? 'مستخدم بلوساب';
                final isFile = item['type'] == 'file';
                final at = DateTime.tryParse(item['at']?.toString() ?? '');
                final stamp = at == null ? '' : '${at.year}-${at.month.toString().padLeft(2,'0')}-${at.day.toString().padLeft(2,'0')}  ${at.hour.toString().padLeft(2,'0')}:${at.minute.toString().padLeft(2,'0')}';
                return BlousabNeonPanel(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: BlousabProfileAvatar(name: sender, radius: 21),
                    title: Text(sender, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(isFile ? 'ملف وارد عبر بلوساب' : 'رسالة واردة عبر بلوساب'),
                    trailing: Text(stamp, style: Theme.of(context).textTheme.labelSmall),
                  ),
                );
              },
            )),
  );
}
