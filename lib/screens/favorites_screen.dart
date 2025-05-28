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

class FavoriteItemCard extends HookWidget {
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
    final allImages = useState<List<File>>([]);
    final isLoading = useState(false);

    // 如果是ID收藏，加载所有图片
    useEffect(() {
      if (item.type == FavoriteType.id) {
        isLoading.value = true;
        _loadAllFavoriteImages().then((images) {
          allImages.value = images;
          isLoading.value = false;
        });
      }
      return null;
    }, [item.id]);

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
                // 左侧信息
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 收藏ID
                      Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => onCopy(item.name, item.type.displayName),
                          child: Text(
                            '${item.type.displayName}: ${item.name}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 创建时间
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '收藏时间: ${_formatDateTime(item.createdAt)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 描述
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.description, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.description!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // 图片数量（仅ID收藏）
                      if (item.type == FavoriteType.id) ...[
                        Row(
                          children: [
                            const Icon(Icons.photo_library, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '图片数量: ${allImages.value.length} 张',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 删除按钮
                        SizedBox(
                          width: 120,
                          child: OutlinedButton.icon(
                            onPressed: onRemove,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('删除'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                      
                      // 车牌收藏的删除按钮
                      if (item.type == FavoriteType.licensePlate) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 120,
                          child: OutlinedButton.icon(
                            onPressed: onRemove,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('删除'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 右侧图片网格（仅ID收藏显示）
                if (item.type == FavoriteType.id)
                  Expanded(
                    child: _buildImageGrid(context, allImages.value),
                  )
                else
                  // 车牌收藏显示默认图标
                  Expanded(
                    child: Center(
                      child: _buildDefaultIcon(),
                    ),
                  ),
              ],
            ),
            
            // 如果是ID收藏且正在加载
            if (item.type == FavoriteType.id && isLoading.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              
            // 日期标签（放在底部）
            if (item.date != null && item.date!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建7张图片的网格布局（参考图片库样式）
  Widget _buildImageGrid(BuildContext context, List<File> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 固定7列
        crossAxisSpacing: 8, // 与图片库一致
        mainAxisSpacing: 8,  // 与图片库一致
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () => _showImageDialog(context, image, images, index),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
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
                    // 根据图片位置设置对齐方式（与图片库一致）
                    alignment: _getImageAlignment(index),
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
                // 文件名显示在底部（与图片库一致）
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
                          Colors.black.withValues(alpha: 0.7),
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

  /// 获取图片对齐方式（与图片库一致）
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

  /// 加载收藏的所有图片
  Future<List<File>> _loadAllFavoriteImages() async {
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
        return [];
      }

      final images = <File>[];
      await for (final entity in favoriteDir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
            images.add(entity);
          }
        }
      }

      // 按文件名排序
      images.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
      return images;
    } catch (e) {
      debugPrint('加载收藏图片失败: $e');
      return [];
    }
  }

  /// 显示图片预览对话框
  void _showImageDialog(BuildContext context, File imageFile, List<File> allImages, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => FavoriteImageDialog(
        item: item,
        initialImageIndex: initialIndex,
        allImages: allImages,
      ),
    );
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
  final int? initialImageIndex;
  final List<File>? allImages;

  const FavoriteImageDialog({
    super.key,
    required this.item,
    this.initialImageIndex,
    this.allImages,
  });

  @override
  Widget build(BuildContext context) {
    final currentImageIndex = useState(initialImageIndex ?? 0);
    final allImagePaths = useState<List<String>>([]);
    final isLoading = useState(true);

    useEffect(() {
      Future.microtask(() async {
        if (allImages != null && allImages!.isNotEmpty) {
          // 使用传入的图片列表
          allImagePaths.value = allImages!.map((f) => f.path).toList();
        } else {
          // 加载所有图片路径
          final paths = await _getAllImagePaths();
          allImagePaths.value = paths;
        }
        isLoading.value = false;
      });
      return null;
    }, []);

    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
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
              child: isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : allImagePaths.value.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('没有找到图片'),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // 图片导航
                            if (allImagePaths.value.length > 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: currentImageIndex.value > 0
                                        ? () => currentImageIndex.value = currentImageIndex.value - 1
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Text('${currentImageIndex.value + 1} / ${allImagePaths.value.length}'),
                                  IconButton(
                                    onPressed: currentImageIndex.value < allImagePaths.value.length - 1
                                        ? () => currentImageIndex.value = currentImageIndex.value + 1
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            
                            // 当前图片
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(allImagePaths.value[currentImageIndex.value]),
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
                            
                            // 图片文件名
                            const SizedBox(height: 8),
                            Text(
                              path.basename(allImagePaths.value[currentImageIndex.value]),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
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