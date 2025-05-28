import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weighbridge_image_similarity_service.dart';
import '../services/favorite_service.dart';
import '../models/favorite_item.dart';
import 'weighbridge_suspicious_images_screen.dart';
import 'weighbridge_duplicate_detection_screen.dart';
import 'favorites_screen.dart';

class WeighbridgeImageGalleryScreen extends HookConsumerWidget {
  const WeighbridgeImageGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState<String?>(null);
    final availableDates = useState<List<String>>([]);
    final isLoading = useState(true);
    final imageSize = useState(150.0); // 图片显示大小
    final isDatePanelCollapsed = useState(false); // 日期面板收起状态

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
        title: const Text('过磅图片库'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          // 车牌筛选
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '车牌筛选',
            onPressed: () => _showLicensePlateFilter(context, ref, selectedDate.value),
          ),
          // 收藏按钮
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: '我的收藏',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
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
                         color: imageSize.value == 100.0 ? Colors.orange : null),
                    const SizedBox(width: 8),
                    Text('小', style: TextStyle(
                      color: imageSize.value == 100.0 ? Colors.orange : null,
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
                         color: imageSize.value == 150.0 ? Colors.orange : null),
                    const SizedBox(width: 8),
                    Text('中', style: TextStyle(
                      color: imageSize.value == 150.0 ? Colors.orange : null,
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
                         color: imageSize.value == 200.0 ? Colors.orange : null),
                    const SizedBox(width: 8),
                    Text('大', style: TextStyle(
                      color: imageSize.value == 200.0 ? Colors.orange : null,
                      fontWeight: imageSize.value == 200.0 ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
            ],
          ),
          // 重复检测
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: '重复检测',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeighbridgeDuplicateDetectionScreen(),
                ),
              );
            },
          ),
          // 可疑图片检测
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: '可疑图片检测',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeighbridgeSuspiciousImagesScreen(),
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
                  Text('暂无过磅图片', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('请先下载过磅记录图片', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : Row(
              children: [
                // 左侧日期选择器
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isDatePanelCollapsed.value ? 50 : 200,
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
                          color: Colors.orange.shade50,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.orange),
                            if (!isDatePanelCollapsed.value) ...[
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '选择日期',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                            IconButton(
                              icon: Icon(
                                isDatePanelCollapsed.value 
                                    ? Icons.keyboard_arrow_right 
                                    : Icons.keyboard_arrow_left,
                                color: Colors.orange,
                                size: 20,
                              ),
                              onPressed: () {
                                isDatePanelCollapsed.value = !isDatePanelCollapsed.value;
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: isDatePanelCollapsed.value ? '展开日期面板' : '收起日期面板',
                            ),
                          ],
                        ),
                      ),
                      if (!isDatePanelCollapsed.value)
                        Expanded(
                          child: ListView.builder(
                            itemCount: availableDates.value.length,
                            itemBuilder: (context, index) {
                              final date = availableDates.value[index];
                              final isSelected = selectedDate.value == date;
                              
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.orange.withOpacity(0.1),
                                title: Text(
                                  date,
                                  style: TextStyle(
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    color: isSelected 
                                        ? Colors.orange 
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
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        snapshot.hasData 
                                            ? '${snapshot.data}' 
                                            : '...',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
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
                      if (isDatePanelCollapsed.value && selectedDate.value != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    selectedDate.value!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                      : WeighbridgeImageGridView(
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
      final customPath = prefs.getString('weighbridge_save_path');
      
      String imagesPath;
      if (customPath != null && customPath.isNotEmpty) {
        imagesPath = path.join(customPath, 'weighbridge');
      } else {
        final currentDir = Directory.current.path;
        
        // 确保路径是绝对路径，不是根目录
        if (currentDir == '/' || currentDir.isEmpty) {
          // 如果当前目录是根目录，使用用户文档目录
          imagesPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'weighbridge');
        } else {
          // 使用相对于当前工作目录的路径
          imagesPath = path.join(currentDir, 'pic', 'weighbridge');
        }
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
      debugPrint('获取过磅可用日期失败: $e');
      return [];
    }
  }

  /// 获取指定日期的图片数量
  Future<int> _getImageCountForDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('weighbridge_save_path');
      
      String datePath;
      if (customPath != null && customPath.isNotEmpty) {
        datePath = path.join(customPath, 'weighbridge', date);
      } else {
        final currentDir = Directory.current.path;
        
        // 确保路径是绝对路径，不是根目录
        if (currentDir == '/' || currentDir.isEmpty) {
          // 如果当前目录是根目录，使用用户文档目录
          datePath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'weighbridge', date);
        } else {
          // 使用相对于当前工作目录的路径
          datePath = path.join(currentDir, 'pic', 'weighbridge', date);
        }
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
      debugPrint('获取过磅图片数量失败: $e');
      return 0;
    }
  }

  /// 显示车牌筛选对话框
  void _showLicensePlateFilter(BuildContext context, WidgetRef ref, String? selectedDate) {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择日期'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => LicensePlateFilterDialog(
        selectedDate: selectedDate,
      ),
    );
  }
}

/// 车牌筛选对话框
class LicensePlateFilterDialog extends HookConsumerWidget {
    final String selectedDate;

    const LicensePlateFilterDialog({
      super.key,
      required this.selectedDate,
    });

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final searchController = useTextEditingController();
      final availableLicensePlates = useState<List<String>>([]);
      final filteredPlates = useState<List<String>>([]);
      final isLoading = useState(true);

      // 加载当天的车牌列表
      useEffect(() {
        Future.microtask(() async {
          final plates = await _getAvailableLicensePlates(selectedDate);
          availableLicensePlates.value = plates;
          filteredPlates.value = plates;
          isLoading.value = false;
        });
        return null;
      }, [selectedDate]);

      // 监听搜索文本变化
      useEffect(() {
        void onSearchChanged() {
          final searchText = searchController.text.toLowerCase();
          if (searchText.isEmpty) {
            filteredPlates.value = availableLicensePlates.value;
          } else {
            filteredPlates.value = availableLicensePlates.value
                .where((plate) => plate.toLowerCase().contains(searchText))
                .toList();
          }
        }
        searchController.addListener(onSearchChanged);
        return () => searchController.removeListener(onSearchChanged);
      }, []);

      return Dialog(
        child: Container(
          width: 400,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 标题
              Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '$selectedDate 车牌筛选',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 搜索框
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: '搜索车牌号...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 车牌列表
              Expanded(
                child: isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPlates.value.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('暂无车牌数据', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPlates.value.length,
                            itemBuilder: (context, index) {
                              final licensePlate = filteredPlates.value[index];
                              final favorites = ref.watch(favoriteServiceProvider);
                              final isFavorited = favorites.any((item) => 
                                item.type == FavoriteType.licensePlate && 
                                item.name == licensePlate
                              );
                              
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.directions_car, color: Colors.orange),
                                  title: Text(
                                    licensePlate,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: FutureBuilder<int>(
                                    future: _getImageCountForLicensePlate(selectedDate, licensePlate),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.hasData ? '${snapshot.data} 张图片' : '加载中...',
                                      );
                                    },
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 收藏按钮
                                      IconButton(
                                        icon: Icon(
                                          isFavorited ? Icons.star : Icons.star_border,
                                          color: isFavorited ? Colors.amber : null,
                                        ),
                                        onPressed: () async {
                                          await ref
                                              .read(favoriteServiceProvider.notifier)
                                              .toggleFavorite(
                                                name: licensePlate,
                                                type: FavoriteType.licensePlate,
                                                date: selectedDate,
                                                description: '车牌收藏',
                                                // 车牌收藏不传递图片
                                              );
                                        },
                                      ),
                                      // 查看按钮
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          ref.read(licensePlateFilterProvider.notifier).setFilter(licensePlate);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('已筛选车牌: $licensePlate'),
                                              backgroundColor: Colors.green,
                                              action: SnackBarAction(
                                                label: '清除筛选',
                                                onPressed: () {
                                                  ref.read(licensePlateFilterProvider.notifier).clearFilter();
                                                },
                                              ),
                                            ),
                                          );
                                        },
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
    }

    /// 获取指定日期的可用车牌列表
    Future<List<String>> _getAvailableLicensePlates(String date) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final customPath = prefs.getString('save_path');
        
        String datePath;
        if (customPath != null && customPath.isNotEmpty) {
          datePath = path.join(customPath, 'weighbridge_images', date);
        } else {
          final currentDir = Directory.current.path;
          
          // 确保路径是绝对路径，不是根目录
          if (currentDir == '/' || currentDir.isEmpty) {
            // 如果当前目录是根目录，使用用户文档目录
            datePath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'weighbridge_images', date);
          } else {
            // 使用相对于当前工作目录的路径
            datePath = path.join(currentDir, 'pic', 'weighbridge_images', date);
          }
        }

        final dateDir = Directory(datePath);
        if (!await dateDir.exists()) {
          return [];
        }

        final licensePlates = <String>{};
        
        await for (final entity in dateDir.list(recursive: true)) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            // 从文件名中提取车牌号（假设文件名格式包含车牌号）
            final licensePlate = _extractLicensePlateFromFileName(fileName);
            if (licensePlate != null) {
              licensePlates.add(licensePlate);
            }
          }
        }

        final sortedPlates = licensePlates.toList();
        sortedPlates.sort();
        return sortedPlates;
      } catch (e) {
        debugPrint('获取车牌列表失败: $e');
        return [];
      }
    }

    /// 从文件名中提取车牌号
    String? _extractLicensePlateFromFileName(String fileName) {
      // 这里需要根据实际的文件命名规则来提取车牌号
      // 假设文件名格式类似: "2024-01-01_12-30-45_川A12345_1.jpg"
      final regex = RegExp(r'[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领A-Z][A-Z]?[A-Z0-9]{4,5}[A-Z0-9挂学警港澳]?');
      final match = regex.firstMatch(fileName);
      return match?.group(0);
    }

    /// 获取指定车牌在指定日期的图片数量
    Future<int> _getImageCountForLicensePlate(String date, String licensePlate) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final customPath = prefs.getString('save_path');
        
        String datePath;
        if (customPath != null && customPath.isNotEmpty) {
          datePath = path.join(customPath, 'weighbridge_images', date);
        } else {
          final currentDir = Directory.current.path;
          
          // 确保路径是绝对路径，不是根目录
          if (currentDir == '/' || currentDir.isEmpty) {
            // 如果当前目录是根目录，使用用户文档目录
            datePath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'weighbridge_images', date);
          } else {
            // 使用相对于当前工作目录的路径
            datePath = path.join(currentDir, 'pic', 'weighbridge_images', date);
          }
        }

        final dateDir = Directory(datePath);
        if (!await dateDir.exists()) {
          return 0;
        }

        int count = 0;
        await for (final entity in dateDir.list(recursive: true)) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            if (fileName.contains(licensePlate)) {
              count++;
            }
          }
        }

        return count;
      } catch (e) {
        debugPrint('获取车牌图片数量失败: $e');
        return 0;
      }
    }
}

class WeighbridgeImageGridView extends HookConsumerWidget {
  final String date;
  final double imageSize;

  const WeighbridgeImageGridView({
    super.key, 
    required this.date,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageGroups = useState<Map<String, List<File>>>({});
    final isLoading = useState(true);
    final suspiciousThreshold = useState(30.0);
    
    // 监听车牌筛选器
    final licensePlateFilter = ref.watch(licensePlateFilterProvider);
    
    // 获取今日可疑图片
    final suspiciousImagesAsync = ref.watch(
      weighbridgeSuspiciousImagesProvider(suspiciousThreshold.value),
    );

    useEffect(() {
      Future.microtask(() async {
        final groups = await _loadWeighbridgeImageGroups(date);
        imageGroups.value = groups;
        isLoading.value = false;
      });
      return null;
    }, [date]);

    // 根据车牌筛选过滤图片组
    final filteredImageGroups = useMemoized(() {
      if (licensePlateFilter.isEmpty) {
        return imageGroups.value;
      }
      
      return Map<String, List<File>>.fromEntries(
        imageGroups.value.entries.where((entry) {
          // 检查过磅记录名称是否包含筛选的车牌号
          final recordName = entry.key;
          final parts = recordName.split('_');
          final carNumber = parts.length > 2 ? parts[2] : '';
          return carNumber.contains(licensePlateFilter);
        }),
      );
    }, [imageGroups.value, licensePlateFilter]);

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredImageGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              licensePlateFilter.isNotEmpty 
                  ? '没有找到车牌 "$licensePlateFilter" 的图片'
                  : '$date 没有过磅图片', 
              style: const TextStyle(color: Colors.grey)
            ),
            if (licensePlateFilter.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(licensePlateFilterProvider.notifier).clearFilter();
                },
                child: const Text('清除筛选'),
              ),
            ],
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // 可疑图片状态栏
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
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
                          ? '发现 $suspiciousCount 张可疑过磅图片'
                          : '未发现可疑过磅图片',
                      style: TextStyle(
                        color: suspiciousCount > 0 ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (suspiciousCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WeighbridgeSuspiciousImagesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.security, size: 16),
                        label: const Text('查看详情'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
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
                  Text('正在检测可疑过磅图片...'),
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
        ),
        
        // 标题栏
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.scale, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  licensePlateFilter.isNotEmpty
                      ? '$date - 车牌筛选: $licensePlateFilter (${filteredImageGroups.keys.length} 个匹配记录)'
                      : '$date (${filteredImageGroups.keys.length} 个过磅记录)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (licensePlateFilter.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(licensePlateFilterProvider.notifier).clearFilter();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('清除筛选'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
        
        // 过磅记录图片列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final recordName = filteredImageGroups.keys.elementAt(index);
              final images = filteredImageGroups[recordName]!;
              
              return WeighbridgeRecordImagesCard(
                recordName: recordName,
                images: images,
                imageSize: imageSize,
                suspiciousImages: suspiciousImagesAsync.maybeWhen(
                  data: (results) => results.map((r) => r.imagePath).toSet(),
                  orElse: () => <String>{},
                ),
                onImagesChanged: () {
                  // 刷新图片列表时重新加载数据
                  Future.microtask(() async {
                    final groups = await _loadWeighbridgeImageGroups(date);
                    imageGroups.value = groups;
                  });
                },
              );
            },
            childCount: filteredImageGroups.keys.length,
          ),
        ),
      ],
    );
  }
}

class WeighbridgeRecordImagesCard extends HookConsumerWidget {
  final String recordName;
  final List<File> images;
  final double imageSize;
  final Set<String> suspiciousImages;
  final VoidCallback? onImagesChanged; // 添加回调用于刷新

  const WeighbridgeRecordImagesCard({
    super.key,
    required this.recordName,
    required this.images,
    required this.imageSize,
    required this.suspiciousImages,
    this.onImagesChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 解析过磅记录名称
    final parts = recordName.split('_');
    final reportId = parts.isNotEmpty ? parts[0].replaceFirst('WB', '') : '';
    final materialName = parts.length > 1 ? parts[1] : '';
    final carNumber = parts.length > 2 ? parts[2] : '';

    // 统计可疑图片数量
    final suspiciousCount = images.where((image) => 
      suspiciousImages.contains(image.path)
    ).length;

    // 检查收藏状态
    final favorites = ref.watch(favoriteServiceProvider);
    final isIdFavorited = favorites.any((item) => 
      item.type == FavoriteType.id && item.name == reportId
    );
    final isLicensePlateFavorited = favorites.any((item) => 
      item.type == FavoriteType.licensePlate && item.name == carNumber
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部信息行
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧相关信息
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
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => _copyToClipboard(context, reportId, 'ID'),
                          child: Text(
                            '过磅ID: $reportId',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                  
                  // 物资名称
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '物资: $materialName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 车牌号码
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, carNumber, '车牌'),
                    onDoubleTap: () => _filterByLicensePlate(context, ref, carNumber),
                    child: Row(
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
                  ),
                  const SizedBox(height: 8),
                  
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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                  child: _buildImageGrid(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 底部操作按钮行
            Row(
              children: [
                // 收藏按钮组
                Row(
                  children: [
                    // ID收藏按钮
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            isIdFavorited ? Icons.star : Icons.star_border,
                            color: isIdFavorited ? Colors.amber : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () async {
                            await ref
                                .read(favoriteServiceProvider.notifier)
                                .toggleFavorite(
                                  name: reportId,
                                  type: FavoriteType.id,
                                  description: '过磅ID收藏',
                                  imagePath: images.isNotEmpty ? images.first.path : null,
                                  allImages: images, // 传递所有图片
                                );
                          },
                          tooltip: isIdFavorited ? '取消收藏ID' : '收藏ID',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          isIdFavorited ? 'ID已收藏' : '收藏ID',
                          style: TextStyle(
                            fontSize: 10,
                            color: isIdFavorited ? Colors.amber : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // 车牌收藏按钮
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLicensePlateFavorited ? Icons.star : Icons.star_border,
                            color: isLicensePlateFavorited ? Colors.amber : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () async {
                            await ref
                                .read(favoriteServiceProvider.notifier)
                                .toggleFavorite(
                                  name: carNumber,
                                  type: FavoriteType.licensePlate,
                                  description: '车牌收藏',
                                  // 车牌收藏不传递图片
                                );
                          },
                          tooltip: isLicensePlateFavorited ? '取消收藏车牌' : '收藏车牌',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          isLicensePlateFavorited ? '车牌已收藏' : '收藏车牌',
                          style: TextStyle(
                            fontSize: 10,
                            color: isLicensePlateFavorited ? Colors.amber : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // 车牌收藏警告提示
                    if (isLicensePlateFavorited && !isIdFavorited) 
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '建议关注此ID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const Spacer(),
                
                // 批量删除按钮
                SizedBox(
                  width: 150,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBatchDeleteDialog(context, images, '全部图片', onImagesChanged),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('批量删除'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    // 固定7列布局，不分类
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
        final isSuspicious = suspiciousImages.contains(image.path);
        
        return GestureDetector(
          onTap: () {
            _showImageDialog(context, image, images, imageIndex, onImagesChanged);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSuspicious ? Colors.red : Colors.grey.shade300,
                width: isSuspicious ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
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
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    // 根据图片位置设置对齐方式
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

  /// 获取图片对齐方式
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

  /// 复制到剪贴板
  void _copyToClipboard(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制$type: $text'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 车牌筛选功能
  void _filterByLicensePlate(BuildContext context, WidgetRef ref, String licensePlate) {
    ref.read(licensePlateFilterProvider.notifier).setFilter(licensePlate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已筛选车牌: $licensePlate'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '清除筛选',
          onPressed: () {
            ref.read(licensePlateFilterProvider.notifier).clearFilter();
          },
        ),
      ),
    );
  }

}

/// 加载指定日期的过磅图片分组
Future<Map<String, List<File>>> _loadWeighbridgeImageGroups(String date) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('weighbridge_save_path');
    
    String datePath;
    if (customPath != null && customPath.isNotEmpty) {
      datePath = path.join(customPath, 'weighbridge', date);
    } else {
      final currentDir = Directory.current.path;
      datePath = path.join(currentDir, 'pic', 'weighbridge', date);
    }

    final dateDir = Directory(datePath);
    if (!await dateDir.exists()) {
      return {};
    }

    final imageGroups = <String, List<File>>{};

    await for (final entity in dateDir.list(followLinks: false)) {
      if (entity is Directory) {
        final recordName = path.basename(entity.path);
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
          imageGroups[recordName] = images;
        }
      }
    }

    return imageGroups;
  } catch (e) {
    debugPrint('加载过磅图片分组失败: $e');
    return {};
  }
}

/// 显示图片预览对话框
void _showImageDialog(BuildContext context, File imageFile, List<File> allImages, int initialIndex, VoidCallback? onImagesChanged) {
  showDialog(
    context: context,
    builder: (context) => WeighbridgeImagePreviewDialog(
      images: allImages,
      initialIndex: initialIndex,
      onImagesChanged: onImagesChanged,
    ),
  );
}

/// 显示批量删除确认对话框
void _showBatchDeleteDialog(BuildContext context, List<File> images, String type, VoidCallback? onImagesChanged) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('批量删除$type'),
      content: Text('确定要删除全部 ${images.length} 张$type吗？此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _batchDeleteImages(context, images, type, onImagesChanged);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}

/// 批量删除图片
Future<void> _batchDeleteImages(BuildContext context, List<File> images, String type, VoidCallback? onImagesChanged) async {
  try {
    int deletedCount = 0;
    int failedCount = 0;

    for (final image in images) {
      try {
        if (await image.exists()) {
          await image.delete();
          deletedCount++;
        }
      } catch (e) {
        failedCount++;
        print('删除图片失败: ${image.path}, 错误: $e');
      }
    }

    // 显示结果
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedCount == 0
                ? '成功删除 $deletedCount 张$type'
                : '删除完成：成功 $deletedCount 张，失败 $failedCount 张',
          ),
          backgroundColor: failedCount == 0 ? Colors.green : Colors.orange,
        ),
      );

      // 刷新页面
      onImagesChanged?.call();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('批量删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 过磅图片预览对话框
class WeighbridgeImagePreviewDialog extends HookWidget {
  final List<File> images;
  final int initialIndex;
  final VoidCallback? onImagesChanged;

  const WeighbridgeImagePreviewDialog({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onImagesChanged,
  });

  /// 获取预览图片对齐方式
  static Alignment _getImageAlignmentForPreview(int imageIndex) {
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
                Row(
                  children: [
                    // 删除单张图片按钮
                    IconButton(
                      onPressed: () => _showDeleteSingleImageDialog(
                        context,
                        images[currentIndex.value],
                        currentIndex,
                      ),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: '删除此图片',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
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

  void _showDeleteSingleImageDialog(
    BuildContext context,
    File imageFile,
    ValueNotifier<int> currentIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图片'),
        content: Text('确定要删除图片 ${path.basename(imageFile.path)} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteSingleImage(context, imageFile, currentIndex);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleImage(
    BuildContext context,
    File imageFile,
    ValueNotifier<int> currentIndex,
  ) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        
        // 从列表中移除已删除的图片
        images.remove(imageFile);
        
        // 如果删除的是最后一张图片，调整索引
        if (currentIndex.value >= images.length && images.isNotEmpty) {
          currentIndex.value = images.length - 1;
        }
        
        // 如果没有图片了，关闭对话框
        if (images.isEmpty) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片已删除'),
            backgroundColor: Colors.green,
          ),
        );

        // 调用回调刷新页面
        onImagesChanged?.call();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 