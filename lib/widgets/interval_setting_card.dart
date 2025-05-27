import 'package:flutter/material.dart';

class IntervalSettingCard extends StatelessWidget {
  final int intervalMinutes;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const IntervalSettingCard({
    super.key,
    required this.intervalMinutes,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '爬虫间隔',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: intervalMinutes,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5分钟')),
                DropdownMenuItem(value: 10, child: Text('10分钟')),
                DropdownMenuItem(value: 15, child: Text('15分钟')),
                DropdownMenuItem(value: 30, child: Text('30分钟')),
                DropdownMenuItem(value: 60, child: Text('1小时')),
                DropdownMenuItem(value: 120, child: Text('2小时')),
                DropdownMenuItem(value: 360, child: Text('6小时')),
              ],
              onChanged: enabled ? (value) => onChanged(value!) : null,
            ),
            const SizedBox(height: 8),
            const Text(
              '设置爬虫自动执行的时间间隔',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 