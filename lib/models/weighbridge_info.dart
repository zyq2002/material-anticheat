// 过磅记录数据模型

class WeighbridgeListResponse {
  final int total;
  final List<WeighbridgeInfo> rows;
  final int code;
  final String msg;

  WeighbridgeListResponse({
    required this.total,
    required this.rows,
    required this.code,
    required this.msg,
  });

  factory WeighbridgeListResponse.fromJson(Map<String, dynamic> json) {
    return WeighbridgeListResponse(
      total: (json['total'] as num).toInt(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => WeighbridgeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String,
    );
  }
}

class WeighbridgeInfo {
  final int reportInfoId;
  final int projectId;
  final String projectName;
  final String weighbridgeName;
  final String materialName;
  final String model;
  final String unitName;
  final String adminxture;
  final String pumpingMethod;
  final String supplyName;
  final int weightM;
  final int weightP;
  final int weightJ;
  final String weightMTime;
  final String createTime;
  final String weightPTime;
  final String state;
  final String checkState;
  final String carNumber;
  final String onlyNumber;
  final String fromType;
  final String userLocation;
  final String? carFrontImage; // 车前照片
  final String? carLeftImage;  // 左侧照片  
  final String? carRightImage; // 右侧照片
  final String? carNumImage;   // 车牌照片
  final double amount;
  final double complexValue;
  final int bulkDensity;
  final double originalAmount;

  WeighbridgeInfo({
    required this.reportInfoId,
    required this.projectId,
    required this.projectName,
    required this.weighbridgeName,
    required this.materialName,
    required this.model,
    required this.unitName,
    required this.adminxture,
    required this.pumpingMethod,
    required this.supplyName,
    required this.weightM,
    required this.weightP,
    required this.weightJ,
    required this.weightMTime,
    required this.createTime,
    required this.weightPTime,
    required this.state,
    required this.checkState,
    required this.carNumber,
    required this.onlyNumber,
    required this.fromType,
    required this.userLocation,
    this.carFrontImage,
    this.carLeftImage,
    this.carRightImage,
    this.carNumImage,
    required this.amount,
    required this.complexValue,
    required this.bulkDensity,
    required this.originalAmount,
  });

  factory WeighbridgeInfo.fromJson(Map<String, dynamic> json) {
    return WeighbridgeInfo(
      reportInfoId: (json['reportInfoId'] as num).toInt(),
      projectId: (json['projectId'] as num).toInt(),
      projectName: json['projectName'] as String? ?? '',
      weighbridgeName: json['weighbridgeName'] as String? ?? '',
      materialName: json['materialName'] as String? ?? '',
      model: json['model'] as String? ?? '',
      unitName: json['unitName'] as String? ?? '',
      adminxture: json['adminxture'] as String? ?? '',
      pumpingMethod: json['pumpingMethod'] as String? ?? '',
      supplyName: json['supplyName'] as String? ?? '',
      weightM: (json['weightM'] as num?)?.toInt() ?? 0,
      weightP: (json['weightP'] as num?)?.toInt() ?? 0,
      weightJ: (json['weightJ'] as num?)?.toInt() ?? 0,
      weightMTime: json['weightMTime'] as String? ?? '',
      createTime: json['createTime'] as String? ?? '',
      weightPTime: json['weightPTime'] as String? ?? '',
      state: json['state'] as String? ?? '',
      checkState: json['checkState'] as String? ?? '',
      carNumber: json['carNumber'] as String? ?? '',
      onlyNumber: json['onlyNumber'] as String? ?? '',
      fromType: json['fromType'] as String? ?? '',
      userLocation: json['userLocation'] as String? ?? '',
      carFrontImage: json['carFrontImage'] as String?,
      carLeftImage: json['carLeftImage'] as String?,
      carRightImage: json['carRightImage'] as String?,
      carNumImage: json['carNumImage'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      complexValue: (json['complexValue'] as num?)?.toDouble() ?? 0.0,
      bulkDensity: (json['bulkDensity'] as num?)?.toInt() ?? 0,
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // 获取所有图片URL列表
  List<WeighbridgeImageInfo> getAllImages() {
    List<WeighbridgeImageInfo> images = [];
    
    // 车前照片（可能有多张）
    if (carFrontImage != null && carFrontImage!.isNotEmpty) {
      final urls = carFrontImage!.split(',');
      for (int i = 0; i < urls.length; i++) {
        images.add(WeighbridgeImageInfo(
          url: urls[i].trim(),
          type: WeighbridgeImageType.carFront,
          index: i + 1,
          fileName: '车前照片${i + 1}',
        ));
      }
    }
    
    // 左侧照片（可能有多张）
    if (carLeftImage != null && carLeftImage!.isNotEmpty) {
      final urls = carLeftImage!.split(',');
      for (int i = 0; i < urls.length; i++) {
        images.add(WeighbridgeImageInfo(
          url: urls[i].trim(),
          type: WeighbridgeImageType.carLeft,
          index: i + 1,
          fileName: '左侧照片${i + 1}',
        ));
      }
    }
    
    // 右侧照片（可能有多张）
    if (carRightImage != null && carRightImage!.isNotEmpty) {
      final urls = carRightImage!.split(',');
      for (int i = 0; i < urls.length; i++) {
        images.add(WeighbridgeImageInfo(
          url: urls[i].trim(),
          type: WeighbridgeImageType.carRight,
          index: i + 1,
          fileName: '右侧照片${i + 1}',
        ));
      }
    }
    
    // 车牌照片
    if (carNumImage != null && carNumImage!.isNotEmpty) {
      images.add(WeighbridgeImageInfo(
        url: carNumImage!.trim(),
        type: WeighbridgeImageType.carPlate,
        index: 1,
        fileName: '车牌照片',
      ));
    }
    
    return images;
  }
}

// 过磅图片信息
class WeighbridgeImageInfo {
  final String url;
  final WeighbridgeImageType type;
  final int index;
  final String fileName;

  WeighbridgeImageInfo({
    required this.url,
    required this.type,
    required this.index,
    required this.fileName,
  });
}

// 过磅图片类型枚举
enum WeighbridgeImageType {
  carFront,  // 车前照片
  carLeft,   // 左侧照片
  carRight,  // 右侧照片
  carPlate,  // 车牌照片
}

extension WeighbridgeImageTypeExtension on WeighbridgeImageType {
  String get displayName {
    switch (this) {
      case WeighbridgeImageType.carFront:
        return '车前照片';
      case WeighbridgeImageType.carLeft:
        return '左侧照片';
      case WeighbridgeImageType.carRight:
        return '右侧照片';
      case WeighbridgeImageType.carPlate:
        return '车牌照片';
    }
  }
} 