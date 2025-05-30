import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_similarity_service.dart';
import 'suspicious_images_screen.dart';

class ImageGalleryScreen extends HookConsumerWidget {
  const ImageGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState<String?>(null);
    final availableDates = useState<List<String>>([]);
    final isLoading = useState(true);
    final imageSize = useState(150.0); // 图片显示大小

    // 初始化可用日期列表
    useEffect(() {
      Future.microtask(() async {
        final dates = await _getAvailableDates();
        availableDates.value = dates;
        if (dates.isNotEmpty) {
          selectedDate.value = dates.first;
        }
        isLoading.value = false;
      });
      return null;
    }, []);

    if (isLoading.value) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('图片库'),
        centerTitle: true,
        actions: [
          // 图片大小控制
          PopupMenuButton<double>(
            icon: const Icon(Icons.photo_size_select_actual),
            tooltip: '图片大小',
            onSelected: (size) {
              imageSize.value = size;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 100.0,
                child: Row(
                  children: [
                    Icon(Icons.photo_size_select_small, 
                         color: imageSize.value == 100.0 ? Colors.blue : null),
                    const SizedBox(width: 8),
                    Text('小', style: TextStyle(
                      color: imageSize.value == 100.0 ? Colors.blue : null,
                      fontWeight: imageSize.value == 100.0 ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 150.0,
                child: Row(
                  children: [
                    Icon(Icons.photo_size_select_actual, 
                         color: imageSize.value == 150.0 ? Colors.blue : null),
                    const SizedBox(width: 8),
                    Text('中', style: TextStyle(
                      color: imageSize.value == 150.0 ? Colors.blue : null,
                      fontWeight: imageSize.value == 150.0 ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 200.0,
                child: Row(
                  children: [
                    Icon(Icons.photo_size_select_large, 
                         color: imageSize.value == 200.0 ? Colors.blue : null),
                    const SizedBox(width: 8),
                    Text('大', style: TextStyle(
                      color: imageSize.value == 200.0 ? Colors.blue : null,
                      fontWeight: imageSize.value == 200.0 ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: '可疑图片检测',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuspiciousImagesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              isLoading.value = true;
              final dates = await _getAvailableDates();
              availableDates.value = dates;
              if (dates.isNotEmpty && selectedDate.value == null) {
                selectedDate.value = dates.first;
              }
              isLoading.value = false;
            },
          ),
        ],
      ),
      body: availableDates.value.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无图片', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Row(
              children: [
                // 左侧日期选择器
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '选择日期',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: availableDates.value.length,
                          itemBuilder: (context, index) {
                            final date = availableDates.value[index];
                            final isSelected = selectedDate.value == date;
                            
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withOpacity(0.1),
                              title: Text(
                                date,
                                style: TextStyle(
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: isSelected 
                                      ? Colors.blue 
                                      : null,
                                ),
                              ),
                              trailing: FutureBuilder<int>(
                                future: _getImageCountForDate(date),
                                builder: (context, snapshot) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      snapshot.hasData 
                                          ? '${snapshot.data}' 
                                          : '...',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                selectedDate.value = date;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 右侧图片展示区域
                Expanded(
                  child: selectedDate.value == null
                      ? const Center(
                          child: Text('请选择日期'),
                        )
                      : ImageGridView(
                          date: selectedDate.value!,
                          imageSize: imageSize.value,
                        ),
                ),
              ],
            ),
    );
  }

  /// 获取可用的日期列表
  Future<List<String>> _getAvailableDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('save_path');
      
      String imagesPath;
      if (customPath != null && customPath.isNotEmpty) {
        imagesPath = path.join(customPath, 'images');
      } else {
        final currentDir = Directory.current.path;
        imagesPath = path.join(currentDir, 'pic', 'images');
      }

      final imagesDir = Directory(imagesPath);
      if (!await imagesDir.exists()) {
        return [];
      }

      final dates = <String>[];
      await for (final entity in imagesDir.list(followLinks: false)) {
        if (entity is Directory) {
          final dirName = path.basename(entity.path);
          // 验证日期格式
          if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dirName)) {
            dates.add(dirName);
          }
        }
      }

      // 按日期倒序排列（最新的在前）
      dates.sort((a, b) => b.compareTo(a));
      return dates;
    } catch (e) {
      debugPrint('获取可用日期失败: $e');
      return [];
    }
  }

  /// 获取指定日期的图片数量
  Future<int> _getImageCountForDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('save_path');
      
      String datePath;
      if (customPath != null && customPath.isNotEmpty) {
        datePath = path.join(customPath, 'images', date);
      } else {
        final currentDir = Directory.current.path;
        datePath = path.join(currentDir, 'pic', 'images', date);
      }

      final dateDir = Directory(datePath);
      if (!await dateDir.exists()) {
        return 0;
      }

      int count = 0;
      await for (final entity in dateDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
              .contains(extension)) {
            count++;
          }
        }
      }

      return count;
    } catch (e) {
      debugPrint('获取图片数量失败: $e');
      return 0;
    }
  }
}

class ImageGridView extends HookConsumerWidget {
  final String date;
  final double imageSize;

  const ImageGridView({
    super.key, 
    required this.date,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageGroups = useState<Map<String, List<File>>>({});
    final isLoading = useState(true);
    final suspiciousThreshold = useState(30.0);
    
    // 获取今日可疑图片
    final suspiciousImagesAsync = ref.watch(
      suspiciousImagesProvider(suspiciousThreshold.value),
    );

    useEffect(() {
      Future.microtask(() async {
        final groups = await _loadImageGroups(date);
        imageGroups.value = groups;
        isLoading.value = false;
      });
      return null;
    }, [date]);

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imageGroups.value.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('$date 没有图片', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 可疑图片状态栏
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: suspiciousImagesAsync.when(
            data: (suspiciousResults) {
              final suspiciousCount = suspiciousResults.length;
              return Row(
                children: [
                  Icon(
                    suspiciousCount > 0 ? Icons.warning : Icons.verified,
                    color: suspiciousCount > 0 ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suspiciousCount > 0 
                        ? '发现 $suspiciousCount 张可疑图片'
                        : '未发现可疑图片',
                    style: TextStyle(
                      color: suspiciousCount > 0 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (suspiciousCount > 0)
                    TextButton.icon(
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('查看详情'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuspiciousImagesScreen(),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
            loading: () => const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('正在检测可疑图片...'),
              ],
            ),
            error: (error, stack) => Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '检测失败: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_library, size: 20),
              const SizedBox(width: 8),
              Text(
                '$date (${imageGroups.value.keys.length} 个验收记录)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: imageGroups.value.keys.length,
            itemBuilder: (context, index) {
              final groupName = imageGroups.value.keys.elementAt(index);
              final images = imageGroups.value[groupName]!;

              // 统计可疑图片数量
              final suspiciousCount = suspiciousImagesAsync.maybeWhen(
                data: (suspiciousResults) {
                  return images.where((imageFile) => 
                    suspiciousResults.any((result) =>
                      result.image1Path == imageFile.path ||
                      result.image2Path == imageFile.path)
                  ).length;
                },
                orElse: () => 0,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧验收记录信息
                      SizedBox(
                        width: 250,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 验收记录名称
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Text(
                                '验收记录: $groupName',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // 图片数量
                            Row(
                              children: [
                                const Icon(Icons.photo_library, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  '图片数量: ${images.length} 张',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                            // 可疑图片警告
                            if (suspiciousCount > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning, size: 16, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '发现 $suspiciousCount 张可疑图片',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 右侧图片网格 - 固定7列
                      Expanded(
                        child: GridView.builder(
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
                            final imageFile = images[imageIndex];
                            
                            // 检查这张图片是否是可疑图片
                            final isSuspicious = suspiciousImagesAsync.maybeWhen(
                              data: (suspiciousResults) {
                                return suspiciousResults.any((result) =>
                                  result.image1Path == imageFile.path ||
                                  result.image2Path == imageFile.path);
                              },
                              orElse: () => false,
                            );
                            
                            return GestureDetector(
                              onTap: () {
                                _showImageDialog(context, imageFile, images, imageIndex);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSuspicious ? Colors.red : Colors.grey.shade300,
                                    width: isSuspicious ? 3 : 1,
                                  ),
                                  boxShadow: isSuspicious ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ] : null,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        imageFile,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
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
                                    if (isSuspicious)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.warning,
                                            color: Colors.white,
                                            size: 16,
                                          ),
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
                                          path.basename(imageFile.path),
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 加载指定日期的图片分组
  Future<Map<String, List<File>>> _loadImageGroups(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('save_path');
      
      String datePath;
      if (customPath != null && customPath.isNotEmpty) {
        datePath = path.join(customPath, 'images', date);
      } else {
        final currentDir = Directory.current.path;
        datePath = path.join(currentDir, 'pic', 'images', date);
      }

      final dateDir = Directory(datePath);
      if (!await dateDir.exists()) {
        return {};
      }

      final groups = <String, List<File>>{};

      await for (final entity in dateDir.list(followLinks: false)) {
        if (entity is Directory) {
          final groupName = path.basename(entity.path);
          final images = <File>[];

          await for (final imageEntity in entity.list(followLinks: false)) {
            if (imageEntity is File) {
              final extension = path.extension(imageEntity.path).toLowerCase();
              if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
                  .contains(extension)) {
                images.add(imageEntity);
              }
            }
          }

          if (images.isNotEmpty) {
            // 按文件名排序
            images.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
            groups[groupName] = images;
          }
        }
      }

      return groups;
    } catch (e) {
      debugPrint('加载图片组失败: $e');
      return {};
    }
  }

  /// 显示图片预览对话框
  void _showImageDialog(BuildContext context, File imageFile, List<File> allImages, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        images: allImages,
        initialIndex: initialIndex,
      ),
    );
  }
}

class ImagePreviewDialog extends HookWidget {
  final List<File> images;
  final int initialIndex;

  const ImagePreviewDialog({
    super.key,
    required this.images,
    required this.initialIndex,
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
                  '${currentIndex.value + 1} / ${images.length}',
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    images[currentIndex.value],
                    fit: BoxFit.contain,
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
                ),
                ElevatedButton.icon(
                  onPressed: currentIndex.value < images.length - 1
                      ? () => currentIndex.value++
                      : null,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('下一张'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 