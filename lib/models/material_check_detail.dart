// 简化的材料检查数据模型 - 只保留图片相关字段

class MaterialCheckDetailResponse {
  final String msg;
  final int code;
  final MaterialCheckDetail? data;

  MaterialCheckDetailResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory MaterialCheckDetailResponse.fromJson(Map<String, dynamic> json) {
    return MaterialCheckDetailResponse(
      msg: json['msg'] as String,
      code: (json['code'] as num).toInt(),
      data: json['data'] != null 
          ? MaterialCheckDetail.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MaterialCheckDetail {
  final int id;
  final String checkCode;
  final String projectName;
  final List<MaterialResp> materialRespList;

  MaterialCheckDetail({
    required this.id,
    required this.checkCode,
    required this.projectName,
    required this.materialRespList,
  });

  factory MaterialCheckDetail.fromJson(Map<String, dynamic> json) {
    return MaterialCheckDetail(
      id: (json['id'] as num).toInt(),
      checkCode: json['checkCode'] as String,
      projectName: json['projectName'] as String,
      materialRespList: (json['materialRespList'] as List<dynamic>)
          .map((e) => MaterialResp.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MaterialResp {
  final int id;
  final String name;
  final String supplierName;
  final String carNo;
  final String? deliveryImg; // 送货单照片
  final List<FileInfo> files; // 验收照片列表

  MaterialResp({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.carNo,
    this.deliveryImg,
    required this.files,
  });

  factory MaterialResp.fromJson(Map<String, dynamic> json) {
    return MaterialResp(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      supplierName: json['supplierName'] as String,
      carNo: json['carNo'] as String,
      deliveryImg: json['deliveryImg'] as String?,
      files: (json['files'] as List<dynamic>)
          .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FileInfo {
  final int id;
  final String fileName;
  final String fileUrl;
  final String fileType;

  FileInfo({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: (json['id'] as num).toInt(),
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
    );
  }
}

// 简化的流程信息 - 只保留获取图片必需的字段
class FlowInfo {
  final int flowInstanceId;
  final String code;
  final int dataId; // incomeCheckId
  final String title;
  final String projectName;
  final String materialNames;

  FlowInfo({
    required this.flowInstanceId,
    required this.code,
    required this.dataId,
    required this.title,
    required this.projectName,
    required this.materialNames,
  });

  factory FlowInfo.fromJson(Map<String, dynamic> json) {
    return FlowInfo(
      flowInstanceId: (json['flowInstanceId'] as num).toInt(),
      code: json['code'] as String,
      dataId: (json['dataId'] as num).toInt(),
      title: json['title'] as String,
      projectName: json['projectName'] as String,
      materialNames: json['materialNames'] as String,
    );
  }
}

class FlowListResponse {
  final int total;
  final List<FlowInfo> rows;
  final int code;
  final String msg;

  FlowListResponse({
    required this.total,
    required this.rows,
    required this.code,
    required this.msg,
  });

  factory FlowListResponse.fromJson(Map<String, dynamic> json) {
    return FlowListResponse(
      total: (json['total'] as num).toInt(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => FlowInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String,
    );
  }
} 