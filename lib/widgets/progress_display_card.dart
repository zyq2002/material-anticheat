import 'package:flutter/material.dart';
import '../services/crawler_service.dart';

class ProgressDisplayCard extends StatelessWidget {
  final CrawlerState state;

  const ProgressDisplayCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isRunning ? Icons.sync : Icons.sync_disabled,
                  color: state.isRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '爬取进度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 状态指示器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isRunning ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: state.isRunning ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                state.isRunning ? '运行中' : '已停止',
                style: TextStyle(
                  color: state.isRunning ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 当前任务
            Text(
              '当前任务: ${state.currentTask}',
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            // 进度条
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isRunning ? Colors.blue : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 进度文本
            Text(
              '${(state.progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // 统计信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总任务', state.totalTasks.toString(), Colors.blue),
                _buildStatItem('已完成', state.completedTasks.toString(), Colors.green),
                _buildStatItem('失败', state.failedTasks.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 