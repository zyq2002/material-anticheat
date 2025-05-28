import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends HookConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteServiceProvider);
    final selectedTab = useState(0);
    final searchController = useTextEditingController();
    final searchText = useState('');

    // 监听搜索文本变化
    useEffect(() {
      void onSearchChanged() {
        searchText.value = searchController.text;
      }
      searchController.addListener(onSearchChanged);
      return () => searchController.removeListener(onSearchChanged);
    }, []);

    // 过滤收藏列表
    final filteredFavorites = useMemoized(() {
      List<FavoriteItem> filtered;
      if (selectedTab.value == 0) {
        // 显示所有收藏
        filtered = favorites;
      } else if (selectedTab.value == 1) {
        // 只显示ID收藏
        filtered = favorites.where((item) => item.type == FavoriteType.id).toList();
      } else {
        // 只显示车牌收藏
        filtered = favorites.where((item) => item.type == FavoriteType.licensePlate).toList();
      }

      if (searchText.value.isNotEmpty) {
        filtered = filtered.where((item) =>
          item.name.toLowerCase().contains(searchText.value.toLowerCase()) ||
          (item.description?.toLowerCase().contains(searchText.value.toLowerCase()) ?? false)
        ).toList();
      }

      return filtered;
    }, [favorites, selectedTab.value, searchText.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        actions: [
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出收藏',
            onPressed: favorites.isEmpty ? null : () => _exportFavorites(context, ref),
          ),
          // 清空收藏按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空收藏',
            onPressed: favorites.isEmpty ? null : () => _clearAllFavorites(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜索收藏的ID或车牌...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // 标签栏
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TabBar(
              controller: useTabController(initialLength: 3),
              onTap: (index) => selectedTab.value = index,
              labelColor: Colors.amber.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.amber.shade700,
              tabs: [
                Tab(
                  icon: const Icon(Icons.star),
                  text: '全部 (${favorites.length})',
                ),
                Tab(
                  icon: const Icon(Icons.perm_identity),
                  text: 'ID (${favorites.where((item) => item.type == FavoriteType.id).length})',
                ),
                Tab(
                  icon: const Icon(Icons.directions_car),
                  text: '车牌 (${favorites.where((item) => item.type == FavoriteType.licensePlate).length})',
                ),
              ],
            ),
          ),

          // 收藏列表
          Expanded(
            child: filteredFavorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchText.value.isNotEmpty ? Icons.search_off : Icons.star_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchText.value.isNotEmpty ? '未找到匹配的收藏' : '暂无收藏',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (searchText.value.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '在图片库中点击收藏按钮来添加收藏',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final item = filteredFavorites[index];
                      return FavoriteItemCard(
                        item: item,
                        onRemove: () => _removeFavorite(context, ref, item),
                        onTap: () => _viewFavoriteImages(context, item),
                        onCopy: (text, type) => _copyToClipboard(context, text, type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFavorites(BuildContext context, WidgetRef ref) async {
    try {
      final csvContent = await ref.read(favoriteServiceProvider.notifier).exportFavoritesToCsv();
      
      // 复制到剪贴板
      await Clipboard.setData(ClipboardData(text: csvContent));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('收藏列表已复制到剪贴板'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllFavorites(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有收藏吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 清空所有收藏
      final favorites = ref.read(favoriteServiceProvider);
      for (final item in favorites) {
        await ref.read(favoriteServiceProvider.notifier).removeFavorite(item.id);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已清空所有收藏'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeFavorite(BuildContext context, WidgetRef ref, FavoriteItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除收藏的${item.type.displayName} "${item.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(favoriteServiceProvider.notifier).removeFavorite(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除收藏的${item.type.displayName} "${item.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _viewFavoriteImages(BuildContext context, FavoriteItem item) {
    if (item.type == FavoriteType.licensePlate) {
      // 车牌收藏不显示图片
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('车牌收藏"${item.name}"不提供图片预览'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      // 直接显示收藏的图片
      showDialog(
        context: context,
        builder: (context) => FavoriteImageDialog(item: item),
      );
    } else {
      // 没有图片的收藏项
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.type.displayName} "${item.name}" 没有关联图片'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

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
}

class FavoriteItemCard extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final Function(String text, String type) onCopy;

  const FavoriteItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图片预览或类型图标
              _buildPreviewImage(),
              
              const SizedBox(width: 16),
              
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                            // 标题
                        Row(
                          children: [
                            Text(
                              item.type.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => onCopy(item.name, item.type.displayName),
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    
                    const SizedBox(height: 4),
                    
                    // 创建时间
                    Text(
                      '收藏时间: ${_formatDateTime(item.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    // 描述
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // 日期
                    if (item.date != null && item.date!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.date!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: onRemove,
                tooltip: '删除收藏',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewImage() {
    // 车牌收藏不显示图片预览
    if (item.type == FavoriteType.licensePlate) {
      return _buildDefaultIcon();
    }

    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      final imageFile = File(item.imagePath!);
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultIcon();
            },
          ),
        ),
      );
    } else {
      return _buildDefaultIcon();
    }
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: item.type == FavoriteType.id 
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.type.icon,
        color: item.type == FavoriteType.id ? Colors.blue : Colors.green,
        size: 32,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 收藏图片预览对话框
class FavoriteImageDialog extends HookWidget {
  final FavoriteItem item;

  const FavoriteImageDialog({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final currentImageIndex = useState(0);
    final allImagePaths = useState<List<String>>([]);

    // 获取所有图片路径
    useEffect(() {
      Future.microtask(() async {
        final paths = await _getAllImagePaths();
        allImagePaths.value = paths;
      });
      return null;
    }, []);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  item.type.icon,
                  color: item.type == FavoriteType.id ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.type.displayName}: ${item.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      // 显示图片数量
                      if (allImagePaths.value.isNotEmpty)
                        Text(
                          '${currentImageIndex.value + 1} / ${allImagePaths.value.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 图片显示区域
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: allImagePaths.value.isNotEmpty
                      ? Image.file(
                          File(allImagePaths.value[currentImageIndex.value]),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '图片加载失败',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '暂无图片',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 图片导航按钮
            if (allImagePaths.value.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: currentImageIndex.value > 0
                        ? () => currentImageIndex.value--
                        : null,
                    icon: const Icon(Icons.navigate_before),
                    label: const Text('上一张'),
                  ),
                  ElevatedButton.icon(
                    onPressed: currentImageIndex.value < allImagePaths.value.length - 1
                        ? () => currentImageIndex.value++
                        : null,
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('下一张'),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // 底部信息
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '收藏时间: ${_formatDateTime(item.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (item.date != null && item.date!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.date!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取所有图片路径
  Future<List<String>> _getAllImagePaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('weighbridge_save_path');
      
      String favoritesPath;
      if (customPath != null && customPath.isNotEmpty) {
        favoritesPath = path.join(customPath, 'favorites', item.name);
      } else {
        final currentDir = Directory.current.path;
        
        // 确保路径是绝对路径，不是根目录
        if (currentDir == '/' || currentDir.isEmpty) {
          // 如果当前目录是根目录，使用用户文档目录
          favoritesPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'favorites', item.name);
        } else {
          // 使用相对于当前工作目录的路径
          favoritesPath = path.join(currentDir, 'pic', 'favorites', item.name);
        }
      }

      final favoriteDir = Directory(favoritesPath);
      if (!await favoriteDir.exists()) {
        // 如果收藏目录不存在，尝试使用单个图片路径
        if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          return [item.imagePath!];
        }
        return [];
      }

      final imagePaths = <String>[];
      await for (final entity in favoriteDir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
            imagePaths.add(entity.path);
          }
        }
      }

      // 按文件名排序
      imagePaths.sort();
      return imagePaths;
    } catch (e) {
      debugPrint('获取收藏图片路径失败: $e');
      // 回退到单个图片路径
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        return [item.imagePath!];
      }
      return [];
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 