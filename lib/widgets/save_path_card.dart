import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SavePathCard extends StatelessWidget {
  final String savePath;
  final ValueChanged<String> onPathChanged;
  final bool enabled;

  const SavePathCard({
    super.key,
    required this.savePath,
    required this.onPathChanged,
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
              '保存路径',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      savePath.isEmpty ? '使用默认路径' : savePath,
                      style: TextStyle(
                        color: savePath.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: enabled ? _selectPath : null,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('选择'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '选择图片保存的根目录，留空使用默认路径',
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

  Future<void> _selectPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      onPathChanged(selectedDirectory);
    }
  }
} 