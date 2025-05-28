import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../models/favorite_item.dart';

part 'favorite_service.g.dart';

@riverpod
class FavoriteService extends _$FavoriteService {
  static const String _favoritesKey = 'favorites';
  
  @override
  List<FavoriteItem> build() {
    _loadFavorites();
    return [];
  }

  /// 从本地存储加载收藏列表
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        final favorites = favoritesList
            .map((json) => FavoriteItem.fromJson(json))
            .toList();
        state = favorites;
      }
    } catch (e) {
      debugPrint('加载收藏列表失败: $e');
    }
  }

  /// 保存收藏列表到本地存储
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(
        state.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      debugPrint('保存收藏列表失败: $e');
    }
  }

  /// 添加收藏
  Future<void> addFavorite({
    required String name,
    required FavoriteType type,
    String? description,
    String? imagePath,
    String? date,
  }) async {
    final newFavorite = FavoriteItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: name,
      createdAt: DateTime.now(),
      description: description,
      imagePath: imagePath,
      date: date,
    );

    state = [...state, newFavorite];
    await _saveFavorites();
  }

  /// 删除收藏
  Future<void> removeFavorite(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _saveFavorites();
  }

  /// 检查是否已收藏（按名称和类型）
  bool isFavorited(String name, FavoriteType type) {
    return state.any((item) => item.name == name && item.type == type);
  }

  /// 切换收藏状态
  Future<void> toggleFavorite({
    required String name,
    required FavoriteType type,
    String? description,
    String? imagePath,
    String? date,
    List<File>? allImages, // 添加所有图片参数
  }) async {
    if (isFavorited(name, type)) {
      // 删除收藏
      final item = state.firstWhere((item) => item.name == name && item.type == type);
      await removeFavorite(item.id);
    } else {
      if (type == FavoriteType.id && allImages != null && allImages.isNotEmpty) {
        // ID类型收藏：复制所有图片
        final copiedImagePaths = await _copyAllImagesForFavorite(allImages, name);
        await addFavorite(
          name: name,
          type: type,
          description: description,
          imagePath: copiedImagePaths.isNotEmpty ? copiedImagePaths.first : null,
          date: date,
        );
      } else if (type == FavoriteType.licensePlate) {
        // 车牌类型收藏：不复制图片
        await addFavorite(
          name: name,
          type: type,
          description: description,
          imagePath: null,
          date: date,
        );
      } else {
        // 其他情况：使用原有逻辑
        await addFavorite(
          name: name,
          type: type,
          description: description,
          imagePath: imagePath,
          date: date,
        );
      }
    }
  }

  /// 为收藏复制图片
  Future<String?> _copyImageForFavorite(String sourcePath, String favoriteItemName) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('weighbridge_save_path');
      
      String favoritesPath;
      if (customPath != null && customPath.isNotEmpty) {
        favoritesPath = path.join(customPath, 'favorites');
      } else {
        final currentDir = Directory.current.path;
        
        // 确保路径是绝对路径，不是根目录
        if (currentDir == '/' || currentDir.isEmpty) {
          // 如果当前目录是根目录，使用用户文档目录
          favoritesPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'favorites');
        } else {
          // 使用相对于当前工作目录的路径
          favoritesPath = path.join(currentDir, 'pic', 'favorites');
        }
      }

      final favoritesDir = Directory(favoritesPath);
      if (!await favoritesDir.exists()) {
        await favoritesDir.create(recursive: true);
      }

      // 处理文件名中的特殊字符，确保文件名安全
      final sanitizedName = favoriteItemName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final extension = path.extension(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(favoritesPath, '${sanitizedName}_$timestamp$extension');

      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e) {
      debugPrint('复制收藏图片失败: $e');
      return null;
    }
  }

  /// 为ID收藏复制所有图片
  Future<List<String>> _copyAllImagesForFavorite(List<File> sourceImages, String favoriteItemName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('weighbridge_save_path');
      
      String favoritesPath;
      if (customPath != null && customPath.isNotEmpty) {
        favoritesPath = path.join(customPath, 'favorites', favoriteItemName);
      } else {
        final currentDir = Directory.current.path;
        
        // 确保路径是绝对路径，不是根目录
        if (currentDir == '/' || currentDir.isEmpty) {
          // 如果当前目录是根目录，使用用户文档目录
          favoritesPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'favorites', favoriteItemName);
        } else {
          // 使用相对于当前工作目录的路径
          favoritesPath = path.join(currentDir, 'pic', 'favorites', favoriteItemName);
        }
      }

      final favoritesDir = Directory(favoritesPath);
      if (!await favoritesDir.exists()) {
        await favoritesDir.create(recursive: true);
      }

      // 处理文件名中的特殊字符，确保文件名安全
      final sanitizedName = favoriteItemName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final copiedPaths = <String>[];

      for (int i = 0; i < sourceImages.length; i++) {
        final sourceFile = sourceImages[i];
        if (!await sourceFile.exists()) continue;

        final extension = path.extension(sourceFile.path);
        final originalFileName = path.basenameWithoutExtension(sourceFile.path);
        final targetFileName = '${sanitizedName}_${i + 1}_$originalFileName$extension';
        final targetPath = path.join(favoritesPath, targetFileName);

        try {
          await sourceFile.copy(targetPath);
          copiedPaths.add(targetPath);
        } catch (e) {
          debugPrint('复制图片失败: ${sourceFile.path}, 错误: $e');
        }
      }

      debugPrint('成功复制 ${copiedPaths.length} 张图片到收藏目录');
      return copiedPaths;
    } catch (e) {
      debugPrint('批量复制收藏图片失败: $e');
      return [];
    }
  }

  /// 获取ID收藏列表
  List<FavoriteItem> getIdFavorites() {
    return state.where((item) => item.type == FavoriteType.id).toList();
  }

  /// 获取车牌收藏列表
  List<FavoriteItem> getLicensePlateFavorites() {
    return state.where((item) => item.type == FavoriteType.licensePlate).toList();
  }

  /// 检查车牌是否被收藏
  bool isLicensePlateFavorited(String licensePlate) {
    return state.any((item) => 
      item.type == FavoriteType.licensePlate && 
      item.name == licensePlate
    );
  }

  /// 根据车牌获取相关的图片路径
  Future<List<String>> getImagesByLicensePlate(String licensePlate, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('save_path');
      
      String imagesPath;
      if (customPath != null && customPath.isNotEmpty) {
        imagesPath = path.join(customPath, 'weighbridge_images', date);
      } else {
        final currentDir = Directory.current.path;
        imagesPath = path.join(currentDir, 'pic', 'weighbridge_images', date);
      }

      final List<String> imagePaths = [];
      final dateDir = Directory(imagesPath);
      
      if (await dateDir.exists()) {
        await for (final entity in dateDir.list(recursive: true)) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            // 检查文件名是否包含车牌号
            if (fileName.contains(licensePlate)) {
              imagePaths.add(entity.path);
            }
          }
        }
      }

      return imagePaths;
    } catch (e) {
      debugPrint('获取车牌图片失败: $e');
      return [];
    }
  }

  /// 导出收藏为CSV格式（简化的Excel替代）
  Future<String> exportFavoritesToCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('类型,名称,创建时间,描述,日期');
    
    for (final item in state) {
      buffer.writeln([
        item.type.displayName,
        item.name,
        item.createdAt.toIso8601String(),
        item.description ?? '',
        item.date ?? '',
      ].join(','));
    }
    
    return buffer.toString();
  }
}

@riverpod
class LicensePlateFilter extends _$LicensePlateFilter {
  @override
  String build() => '';

  void setFilter(String licensePlate) {
    state = licensePlate;
  }

  void clearFilter() {
    state = '';
  }
} 