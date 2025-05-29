class WeighbridgeSuspiciousImageResult {
  final String imagePath;
  final String recordName;
  final String imageType;
  final double similarity;
  final String matchImagePath;
  final String matchRecordName;
  final DateTime detectionTime;

  const WeighbridgeSuspiciousImageResult({
    required this.imagePath,
    required this.recordName,
    required this.imageType,
    required this.similarity,
    required this.matchImagePath,
    required this.matchRecordName,
    required this.detectionTime,
  });

  factory WeighbridgeSuspiciousImageResult.fromJson(Map<String, dynamic> json) {
    return WeighbridgeSuspiciousImageResult(
      imagePath: json['imagePath'] as String,
      recordName: json['recordName'] as String,
      imageType: json['imageType'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      matchImagePath: json['matchImagePath'] as String,
      matchRecordName: json['matchRecordName'] as String,
      detectionTime: DateTime.parse(json['detectionTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'recordName': recordName,
      'imageType': imageType,
      'similarity': similarity,
      'matchImagePath': matchImagePath,
      'matchRecordName': matchRecordName,
      'detectionTime': detectionTime.toIso8601String(),
    };
  }
} 