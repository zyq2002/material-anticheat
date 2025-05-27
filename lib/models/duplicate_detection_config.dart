class DuplicateDetectionConfig {
  final double threshold;
  final int compareDays;
  final bool comparePhotos1;
  final bool comparePhotos2;
  final bool comparePhotos3;
  final bool compareDeliveryNotes;
  final bool enableDetailedLog;

  const DuplicateDetectionConfig({
    this.threshold = 0.8,
    this.compareDays = 1,
    this.comparePhotos1 = true,
    this.comparePhotos2 = true,
    this.comparePhotos3 = true,
    this.compareDeliveryNotes = false,
    this.enableDetailedLog = false,
  });

  DuplicateDetectionConfig copyWith({
    double? threshold,
    int? compareDays,
    bool? comparePhotos1,
    bool? comparePhotos2,
    bool? comparePhotos3,
    bool? compareDeliveryNotes,
    bool? enableDetailedLog,
  }) {
    return DuplicateDetectionConfig(
      threshold: threshold ?? this.threshold,
      compareDays: compareDays ?? this.compareDays,
      comparePhotos1: comparePhotos1 ?? this.comparePhotos1,
      comparePhotos2: comparePhotos2 ?? this.comparePhotos2,
      comparePhotos3: comparePhotos3 ?? this.comparePhotos3,
      compareDeliveryNotes: compareDeliveryNotes ?? this.compareDeliveryNotes,
      enableDetailedLog: enableDetailedLog ?? this.enableDetailedLog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'threshold': threshold,
      'compareDays': compareDays,
      'comparePhotos1': comparePhotos1,
      'comparePhotos2': comparePhotos2,
      'comparePhotos3': comparePhotos3,
      'compareDeliveryNotes': compareDeliveryNotes,
      'enableDetailedLog': enableDetailedLog,
    };
  }

  factory DuplicateDetectionConfig.fromJson(Map<String, dynamic> json) {
    return DuplicateDetectionConfig(
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.8,
      compareDays: json['compareDays'] as int? ?? 1,
      comparePhotos1: json['comparePhotos1'] as bool? ?? true,
      comparePhotos2: json['comparePhotos2'] as bool? ?? true,
      comparePhotos3: json['comparePhotos3'] as bool? ?? true,
      compareDeliveryNotes: json['compareDeliveryNotes'] as bool? ?? false,
      enableDetailedLog: json['enableDetailedLog'] as bool? ?? false,
    );
  }
}

class DetectionProgress {
  final int current;
  final int total;
  final String currentTask;
  final bool isCompleted;
  final String? errorMessage;

  const DetectionProgress({
    required this.current,
    required this.total,
    required this.currentTask,
    this.isCompleted = false,
    this.errorMessage,
  });

  DetectionProgress copyWith({
    int? current,
    int? total,
    String? currentTask,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return DetectionProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      currentTask: currentTask ?? this.currentTask,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'total': total,
      'currentTask': currentTask,
      'isCompleted': isCompleted,
      'errorMessage': errorMessage,
    };
  }

  factory DetectionProgress.fromJson(Map<String, dynamic> json) {
    return DetectionProgress(
      current: json['current'] as int,
      total: json['total'] as int,
      currentTask: json['currentTask'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
} 