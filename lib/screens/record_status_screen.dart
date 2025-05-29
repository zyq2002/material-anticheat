import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/record_status.dart';
import '../services/record_status_service.dart';

class RecordStatusScreen extends HookConsumerWidget {
  const RecordStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordStatusItems = ref.watch(recordStatusServiceProvider);
    final selectedStatus = useState<RecordStatusType?>(null);

    // 根据选择的状态筛选记录
    final filteredItems = useMemoized(() {
      if (selectedStatus.value == null) {
        return recordStatusItems;
      }
      return recordStatusItems.where((item) => item.status == selectedStatus.value).toList();
    }, [recordStatusItems, selectedStatus.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录状态管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 状态筛选按钮
          PopupMenuButton<RecordStatusType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选状态',
            onSelected: (status) {
              selectedStatus.value = status;
            },
            itemBuilder: (context) => [
              PopupMenuItem<RecordStatusType?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('全部记录'),
                  ],
                ),
              ),
              PopupMenuItem<RecordStatusType?>(
                value: RecordStatusType.suspicious,
                child: Row(
                  children: [
                    Icon(RecordStatusType.suspicious.icon, 
                         color: RecordStatusType.suspicious.color),
                    const SizedBox(width: 8),
                    Text(RecordStatusType.suspicious.displayName),
                  ],
                ),
              ),
              PopupMenuItem<RecordStatusType?>(
                value: RecordStatusType.normal,
                child: Row(
                  children: [
                    Icon(RecordStatusType.normal.icon, 
                         color: RecordStatusType.normal.color),
                    const SizedBox(width: 8),
                    Text(RecordStatusType.normal.displayName),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态统计栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCard(
                  '全部记录',
                  recordStatusItems.length.toString(),
                  Colors.blue,
                  Icons.list,
                ),
                _buildStatusCard(
                  '可疑记录',
                  recordStatusItems.where((item) => item.status == RecordStatusType.suspicious).length.toString(),
                  RecordStatusType.suspicious.color,
                  RecordStatusType.suspicious.icon,
                ),
                _buildStatusCard(
                  '正常记录',
                  recordStatusItems.where((item) => item.status == RecordStatusType.normal).length.toString(),
                  RecordStatusType.normal.color,
                  RecordStatusType.normal.icon,
                ),
              ],
            ),
          ),
          
          // 筛选提示栏
          if (selectedStatus.value != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: selectedStatus.value!.backgroundColor,
              child: Row(
                children: [
                  Icon(selectedStatus.value!.icon, 
                       color: selectedStatus.value!.color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '当前筛选: ${selectedStatus.value!.displayName} (${filteredItems.length} 条记录)',
                    style: TextStyle(
                      color: selectedStatus.value!.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      selectedStatus.value = null;
                    },
                    child: const Text('清除筛选'),
                  ),
                ],
              ),
            ),

          // 记录列表
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedStatus.value?.icon ?? Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedStatus.value == null
                              ? '暂无标记记录'
                              : '暂无${selectedStatus.value!.displayName}记录',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return RecordStatusItemCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 记录状态项目卡片组件
class RecordStatusItemCard extends HookConsumerWidget {
  final RecordStatusItem item;

  const RecordStatusItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = useState<List<File>>([]);
    final isLoading = useState(true);

    // 加载图片
    useEffect(() {
      Future.microtask(() async {
        final loadedImages = await _loadImages();
        images.value = loadedImages;
        isLoading.value = false;
      });
      return null;
    }, [item.allImagePaths]);

    // 解析记录名称获取车牌
    final parts = item.recordName.split('__');
    final carNumber = parts.length > 1 ? parts[1] : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.status.borderColor,
            width: 2,
          ),
          color: item.status.backgroundColor,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态标识栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: item.status.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.status.icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.status.displayName}记录',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${item.description})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 主要内容行
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧记录信息
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 过磅ID
                      Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.status.color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '过磅ID: ${item.weighbridgeId}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.status.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 车牌号码
                      if (carNumber.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '车牌: $carNumber',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // 图片数量
                      Row(
                        children: [
                          const Icon(Icons.photo_library, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '图片数量: ${images.value.length} 张',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 标记时间
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '标记时间: ${_formatDateTime(item.createdAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // 关联日期
                      if (item.date != null && item.date!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '关联日期: ${item.date}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 右侧图片网格 - 固定7列
                Expanded(
                  child: isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : images.value.isEmpty
                          ? Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, 
                                         size: 32, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('暂无图片', 
                                         style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          : _buildImageGrid(context, images.value),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 底部操作按钮行
            Row(
              children: [
                // 编辑备注按钮
                OutlinedButton.icon(
                  onPressed: () => _editDescription(context, ref),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('编辑备注'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: item.status.color,
                    side: BorderSide(color: item.status.color),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 查看图片按钮
                if (images.value.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showImageDialog(context, images.value, 0),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('查看图片'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.status.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                const Spacer(),
                
                // 移除标记按钮
                OutlinedButton.icon(
                  onPressed: () => _removeRecordStatus(context, ref),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('移除标记'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<File> images) {
    // 固定7列布局，与收藏页面一致
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 固定7列
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, imageIndex) {
        final image = images[imageIndex];
        
        return GestureDetector(
          onTap: () {
            _showImageDialog(context, images, imageIndex);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: item.status.borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    // 根据图片位置设置对齐方式（与收藏页面一致）
                    alignment: _getImageAlignment(imageIndex),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                // 文件名显示在底部
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      path.basename(image.path),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 获取图片对齐方式（与收藏页面一致）
  Alignment _getImageAlignment(int imageIndex) {
    // 第一第二张图片（索引0,1）偏右显示顶头
    if (imageIndex == 0 || imageIndex == 1) {
      return Alignment.topRight;
    }
    // 第三第四张图片（索引2,3）偏左显示顶头
    else if (imageIndex == 2 || imageIndex == 3) {
      return Alignment.topLeft;
    }
    // 其他图片保持居中
    else {
      return Alignment.center;
    }
  }

  /// 加载图片文件
  Future<List<File>> _loadImages() async {
    if (item.allImagePaths == null || item.allImagePaths!.isEmpty) {
      return [];
    }

    final imageFiles = <File>[];
    for (final imagePath in item.allImagePaths!) {
      final file = File(imagePath);
      if (await file.exists()) {
        imageFiles.add(file);
      }
    }

    return imageFiles;
  }

  /// 显示图片预览对话框
  void _showImageDialog(BuildContext context, List<File> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => RecordStatusImagePreviewDialog(
        images: images,
        initialIndex: initialIndex,
        recordItem: item,
      ),
    );
  }

  /// 编辑备注
  Future<void> _editDescription(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: item.description ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑备注 - ${item.weighbridgeId}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注信息...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(recordStatusServiceProvider.notifier).setRecordStatus(
        recordName: item.recordName,
        weighbridgeId: item.weighbridgeId,
        status: item.status,
        description: result.isEmpty ? null : result,
        date: item.date,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('备注已更新'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 移除记录状态
  Future<void> _removeRecordStatus(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除 ${item.weighbridgeId} 的状态标记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(recordStatusServiceProvider.notifier).removeRecordStatus(item.recordName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('状态标记已移除'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 记录状态图片预览对话框
class RecordStatusImagePreviewDialog extends HookWidget {
  final List<File> images;
  final int initialIndex;
  final RecordStatusItem recordItem;

  const RecordStatusImagePreviewDialog({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.recordItem,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(initialIndex);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${recordItem.status.displayName}记录 - ${recordItem.weighbridgeId} (${currentIndex.value + 1} / ${images.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: recordItem.status.borderColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    images[currentIndex.value],
                    fit: BoxFit.contain,
                    // 根据图片位置设置对齐方式
                    alignment: _getImageAlignmentForPreview(currentIndex.value),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              path.basename(images[currentIndex.value].path),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: currentIndex.value > 0
                      ? () => currentIndex.value--
                      : null,
                  icon: const Icon(Icons.navigate_before),
                  label: const Text('上一张'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recordItem.status.color,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: currentIndex.value < images.length - 1
                      ? () => currentIndex.value++
                      : null,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('下一张'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recordItem.status.color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取预览图片对齐方式
  Alignment _getImageAlignmentForPreview(int imageIndex) {
    // 第一第二张图片（索引0,1）偏右显示顶头
    if (imageIndex == 0 || imageIndex == 1) {
      return Alignment.topRight;
    }
    // 第三第四张图片（索引2,3）偏左显示顶头
    else if (imageIndex == 2 || imageIndex == 3) {
      return Alignment.topLeft;
    }
    // 其他图片保持居中
    else {
      return Alignment.center;
    }
  }
} 