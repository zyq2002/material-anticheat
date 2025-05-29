import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../models/favorite_item.dart';

// 创建一个简单的Provider
final favoriteServiceProvider = StateNotifierProvider<FavoriteService, List<FavoriteItem>>((ref) {
  return FavoriteService();
});

class FavoriteService extends StateNotifier<List<FavoriteItem>> {
  static const String _favoritesKey = 'favorites';
  
  FavoriteService() : super([]) {
    _loadFavorites();
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
        
        // 按过磅时间排序收藏列表
        await _sortFavoritesByWeighbridgeTime(favorites);
        state = favorites;
      }
    } catch (e) {
      debugPrint('加载收藏列表失败: $e');
    }
  }

  /// 按过磅ID排序收藏列表
  Future<void> _sortFavoritesByWeighbridgeTime(List<FavoriteItem> favorites) async {
    // 按过磅ID排序（ID类型收藏按ID数字排序，车牌收藏按收藏时间排序）
    favorites.sort((a, b) {
      // 如果都是ID类型收藏，按ID数字排序（大的在前）
      if (a.type == FavoriteType.id && b.type == FavoriteType.id) {
        try {
          final aId = int.tryParse(a.name) ?? 0;
          final bId = int.tryParse(b.name) ?? 0;
          return bId.compareTo(aId); // 降序，大的ID在前
        } catch (e) {
          // 如果解析失败，按字符串排序
          return b.name.compareTo(a.name);
        }
      }
      
      // 如果都是车牌收藏，按收藏时间排序（新的在前）
      if (a.type == FavoriteType.licensePlate && b.type == FavoriteType.licensePlate) {
        return b.createdAt.compareTo(a.createdAt);
      }
      
      // 如果类型不同，ID收藏优先显示在前面
      if (a.type == FavoriteType.id && b.type == FavoriteType.licensePlate) {
        return -1;
      } else if (a.type == FavoriteType.licensePlate && b.type == FavoriteType.id) {
        return 1;
      }
      
      // 默认按收藏时间排序
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// 获取收藏项目的过磅时间
  Future<DateTime> _getWeighbridgeTimeForFavorite(FavoriteItem favorite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('weighbridge_save_path');
      
      // 首先尝试从收藏的图片路径获取过磅时间
      if (favorite.imagePath != null && favorite.imagePath!.isNotEmpty) {
        final imageFile = File(favorite.imagePath!);
        if (await imageFile.exists()) {
          final imageDir = Directory(path.dirname(imageFile.path));
          final recordInfoFile = File(path.join(imageDir.path, 'record_info.json'));
          
          if (await recordInfoFile.exists()) {
            final jsonContent = await recordInfoFile.readAsString();
            final recordData = jsonDecode(jsonContent) as Map<String, dynamic>;
            final createTimeStr = recordData['createTime'] as String?;
            
            if (createTimeStr != null && createTimeStr.isNotEmpty) {
              return DateTime.parse(createTimeStr.replaceAll(' ', 'T'));
            }
          }
        }
      }
      
      // 如果从收藏图片路径获取不到，尝试从过磅记录目录获取
      String weighbridgePath;
      if (customPath != null && customPath.isNotEmpty) {
        weighbridgePath = path.join(customPath, 'weighbridge');
      } else {
        final currentDir = Directory.current.path;
        weighbridgePath = path.join(currentDir, 'pic', 'weighbridge');
      }
      
      final weighbridgeDir = Directory(weighbridgePath);
      if (await weighbridgeDir.exists()) {
        // 遍历日期目录寻找匹配的记录
        await for (final dateEntity in weighbridgeDir.list()) {
          if (dateEntity is Directory) {
            await for (final recordEntity in dateEntity.list()) {
              if (recordEntity is Directory) {
                final recordName = path.basename(recordEntity.path);
                // 检查记录名称是否包含收藏的ID
                if (recordName.contains(favorite.name)) {
                  final recordInfoFile = File(path.join(recordEntity.path, 'record_info.json'));
                  if (await recordInfoFile.exists()) {
                    final jsonContent = await recordInfoFile.readAsString();
                    final recordData = jsonDecode(jsonContent) as Map<String, dynamic>;
                    final createTimeStr = recordData['createTime'] as String?;
                    
                    if (createTimeStr != null && createTimeStr.isNotEmpty) {
                      return DateTime.parse(createTimeStr.replaceAll(' ', 'T'));
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // 如果都获取不到，返回收藏时间
      return favorite.createdAt;
    } catch (e) {
      debugPrint('获取收藏项目过磅时间失败: $e');
      return favorite.createdAt;
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
    String? licensePlate,
    String? materialName,
  }) async {
    final newFavorite = FavoriteItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: name,
      createdAt: DateTime.now(),
      description: description,
      imagePath: imagePath,
      date: date,
      licensePlate: licensePlate,
      materialName: materialName,
    );

    final updatedList = [...state, newFavorite];
    // 添加收藏后重新按过磅时间排序
    await _sortFavoritesByWeighbridgeTime(updatedList);
    state = updatedList;
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
    String? licensePlate,
    String? materialName,
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
          licensePlate: licensePlate,
          materialName: materialName,
        );
      } else if (type == FavoriteType.licensePlate) {
        // 车牌类型收藏：不复制图片
        await addFavorite(
          name: name,
          type: type,
          description: description,
          imagePath: null,
          date: date,
          licensePlate: licensePlate,
          materialName: materialName,
        );
      } else {
        // 其他情况：使用原有逻辑
        await addFavorite(
          name: name,
          type: type,
          description: description,
          imagePath: imagePath,
          date: date,
          licensePlate: licensePlate,
          materialName: materialName,
        );
      }
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
          favoritesPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'favorites', favoriteItemName);
        } else {
          favoritesPath = path.join(currentDir, 'pic', 'favorites', favoriteItemName);
        }
      }

      final favoritesDir = Directory(favoritesPath);
      if (!await favoritesDir.exists()) {
        await favoritesDir.create(recursive: true);
      }

      final copiedPaths = <String>[];
      
      // 如果有源图片，尝试复制record_info.json文件
      if (sourceImages.isNotEmpty) {
        try {
          final sourceDir = Directory(path.dirname(sourceImages.first.path));
          final sourceRecordInfoFile = File(path.join(sourceDir.path, 'record_info.json'));
          
          if (await sourceRecordInfoFile.exists()) {
            final targetRecordInfoFile = File(path.join(favoritesPath, 'record_info.json'));
            if (!await targetRecordInfoFile.exists()) {
              await sourceRecordInfoFile.copy(targetRecordInfoFile.path);
              debugPrint('复制过磅记录信息文件: ${targetRecordInfoFile.path}');
            }
          }
        } catch (e) {
          debugPrint('复制record_info.json失败: $e');
        }
      }
      
      for (final sourceImage in sourceImages) {
        try {
          if (await sourceImage.exists()) {
            final fileName = path.basename(sourceImage.path);
            final targetPath = path.join(favoritesPath, fileName);
            
            // 如果目标文件不存在则复制
            final targetFile = File(targetPath);
            if (!await targetFile.exists()) {
              await sourceImage.copy(targetPath);
              copiedPaths.add(targetPath);
            } else {
              copiedPaths.add(targetPath);
            }
          }
        } catch (e) {
          debugPrint('复制图片 ${sourceImage.path} 失败: $e');
        }
      }

      return copiedPaths;
    } catch (e) {
      debugPrint('为收藏复制所有图片失败: $e');
      return [];
    }
  }

  /// 导出收藏列表为CSV
  Future<String> exportFavoritesToCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('类型,名称,描述,收藏时间,关联日期');
    
    for (final item in state) {
      final type = item.type.displayName;
      final name = item.name;
      final description = item.description ?? '';
      final createdAt = '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
      final date = item.date ?? '';
      
      buffer.writeln('"$type","$name","$description","$createdAt","$date"');
    }
    
    return buffer.toString();
  }
} 