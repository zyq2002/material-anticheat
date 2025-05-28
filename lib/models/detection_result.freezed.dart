// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_annotation_target, unnecessary_question_mark

part of 'detection_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DetectionResult _$DetectionResultFromJson(Map<String, dynamic> json) {
  return _DetectionResult.fromJson(json);
}

/// @nodoc
mixin _$DetectionResult {
  String get id => throw _privateConstructorUsedError;
  String get detectionType => throw _privateConstructorUsedError;
  DateTime get detectionTime => throw _privateConstructorUsedError;
  String get imagePath1 => throw _privateConstructorUsedError;
  String get imagePath2 => throw _privateConstructorUsedError;
  String get recordName1 => throw _privateConstructorUsedError;
  String get recordName2 => throw _privateConstructorUsedError;
  double get similarity => throw _privateConstructorUsedError;
  String get imageType => throw _privateConstructorUsedError;
  SimilarityLevel get level => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get reviewedBy => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DetectionResultCopyWith<DetectionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionResultCopyWith<$Res> {
  factory $DetectionResultCopyWith(
          DetectionResult value, $Res Function(DetectionResult) then) =
      _$DetectionResultCopyWithImpl<$Res, DetectionResult>;
  @useResult
  $Res call(
      {String id,
      String detectionType,
      DateTime detectionTime,
      String imagePath1,
      String imagePath2,
      String recordName1,
      String recordName2,
      double similarity,
      String imageType,
      SimilarityLevel level,
      String status,
      String? notes,
      String? reviewedBy,
      DateTime? reviewedAt});
}

/// @nodoc
class _$DetectionResultCopyWithImpl<$Res, $Val extends DetectionResult>
    implements $DetectionResultCopyWith<$Res> {
  _$DetectionResultCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? detectionType = null,
    Object? detectionTime = null,
    Object? imagePath1 = null,
    Object? imagePath2 = null,
    Object? recordName1 = null,
    Object? recordName2 = null,
    Object? similarity = null,
    Object? imageType = null,
    Object? level = null,
    Object? status = null,
    Object? notes = freezed,
    Object? reviewedBy = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      detectionType: null == detectionType ? _value.detectionType : detectionType as String,
      detectionTime: null == detectionTime ? _value.detectionTime : detectionTime as DateTime,
      imagePath1: null == imagePath1 ? _value.imagePath1 : imagePath1 as String,
      imagePath2: null == imagePath2 ? _value.imagePath2 : imagePath2 as String,
      recordName1: null == recordName1 ? _value.recordName1 : recordName1 as String,
      recordName2: null == recordName2 ? _value.recordName2 : recordName2 as String,
      similarity: null == similarity ? _value.similarity : similarity as double,
      imageType: null == imageType ? _value.imageType : imageType as String,
      level: null == level ? _value.level : level as SimilarityLevel,
      status: null == status ? _value.status : status as String,
      notes: freezed == notes ? _value.notes : notes as String?,
      reviewedBy: freezed == reviewedBy ? _value.reviewedBy : reviewedBy as String?,
      reviewedAt: freezed == reviewedAt ? _value.reviewedAt : reviewedAt as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectionResultImplCopyWith<$Res>
    implements $DetectionResultCopyWith<$Res> {
  factory _$$DetectionResultImplCopyWith(_$DetectionResultImpl value,
          $Res Function(_$DetectionResultImpl) then) =
      __$$DetectionResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String detectionType,
      DateTime detectionTime,
      String imagePath1,
      String imagePath2,
      String recordName1,
      String recordName2,
      double similarity,
      String imageType,
      SimilarityLevel level,
      String status,
      String? notes,
      String? reviewedBy,
      DateTime? reviewedAt});
}

/// @nodoc
class __$$DetectionResultImplCopyWithImpl<$Res>
    extends _$DetectionResultCopyWithImpl<$Res, _$DetectionResultImpl>
    implements _$$DetectionResultImplCopyWith<$Res> {
  __$$DetectionResultImplCopyWithImpl(
      _$DetectionResultImpl _value, $Res Function(_$DetectionResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? detectionType = null,
    Object? detectionTime = null,
    Object? imagePath1 = null,
    Object? imagePath2 = null,
    Object? recordName1 = null,
    Object? recordName2 = null,
    Object? similarity = null,
    Object? imageType = null,
    Object? level = null,
    Object? status = null,
    Object? notes = freezed,
    Object? reviewedBy = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(_$DetectionResultImpl(
      id: null == id ? _value.id : id as String,
      detectionType: null == detectionType ? _value.detectionType : detectionType as String,
      detectionTime: null == detectionTime ? _value.detectionTime : detectionTime as DateTime,
      imagePath1: null == imagePath1 ? _value.imagePath1 : imagePath1 as String,
      imagePath2: null == imagePath2 ? _value.imagePath2 : imagePath2 as String,
      recordName1: null == recordName1 ? _value.recordName1 : recordName1 as String,
      recordName2: null == recordName2 ? _value.recordName2 : recordName2 as String,
      similarity: null == similarity ? _value.similarity : similarity as double,
      imageType: null == imageType ? _value.imageType : imageType as String,
      level: null == level ? _value.level : level as SimilarityLevel,
      status: null == status ? _value.status : status as String,
      notes: freezed == notes ? _value.notes : notes as String?,
      reviewedBy: freezed == reviewedBy ? _value.reviewedBy : reviewedBy as String?,
      reviewedAt: freezed == reviewedAt ? _value.reviewedAt : reviewedAt as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectionResultImpl implements _DetectionResult {
  const _$DetectionResultImpl(
      {required this.id,
      required this.detectionType,
      required this.detectionTime,
      required this.imagePath1,
      required this.imagePath2,
      required this.recordName1,
      required this.recordName2,
      required this.similarity,
      required this.imageType,
      required this.level,
      this.status = 'pending',
      this.notes,
      this.reviewedBy,
      this.reviewedAt});

  factory _$DetectionResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectionResultImplFromJson(json);

  @override
  final String id;
  @override
  final String detectionType;
  @override
  final DateTime detectionTime;
  @override
  final String imagePath1;
  @override
  final String imagePath2;
  @override
  final String recordName1;
  @override
  final String recordName2;
  @override
  final double similarity;
  @override
  final String imageType;
  @override
  final SimilarityLevel level;
  @override
  @JsonKey()
  final String status;
  @override
  final String? notes;
  @override
  final String? reviewedBy;
  @override
  final DateTime? reviewedAt;

  @override
  String toString() {
    return 'DetectionResult(id: $id, detectionType: $detectionType, detectionTime: $detectionTime, imagePath1: $imagePath1, imagePath2: $imagePath2, recordName1: $recordName1, recordName2: $recordName2, similarity: $similarity, imageType: $imageType, level: $level, status: $status, notes: $notes, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.detectionType, detectionType) ||
                other.detectionType == detectionType) &&
            (identical(other.detectionTime, detectionTime) ||
                other.detectionTime == detectionTime) &&
            (identical(other.imagePath1, imagePath1) ||
                other.imagePath1 == imagePath1) &&
            (identical(other.imagePath2, imagePath2) ||
                other.imagePath2 == imagePath2) &&
            (identical(other.recordName1, recordName1) ||
                other.recordName1 == recordName1) &&
            (identical(other.recordName2, recordName2) ||
                other.recordName2 == recordName2) &&
            (identical(other.similarity, similarity) ||
                other.similarity == similarity) &&
            (identical(other.imageType, imageType) ||
                other.imageType == imageType) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      detectionType,
      detectionTime,
      imagePath1,
      imagePath2,
      recordName1,
      recordName2,
      similarity,
      imageType,
      level,
      status,
      notes,
      reviewedBy,
      reviewedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionResultImplCopyWith<_$DetectionResultImpl> get copyWith =>
      __$$DetectionResultImplCopyWithImpl<_$DetectionResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectionResultImplToJson(this);
  }
}

abstract class _DetectionResult implements DetectionResult {
  const factory _DetectionResult(
      {required final String id,
      required final String detectionType,
      required final DateTime detectionTime,
      required final String imagePath1,
      required final String imagePath2,
      required final String recordName1,
      required final String recordName2,
      required final double similarity,
      required final String imageType,
      required final SimilarityLevel level,
      final String status,
      final String? notes,
      final String? reviewedBy,
      final DateTime? reviewedAt}) = _$DetectionResultImpl;

  factory _DetectionResult.fromJson(Map<String, dynamic> json) =
      _$DetectionResultImpl.fromJson;

  @override
  String get id;
  @override
  String get detectionType;
  @override
  DateTime get detectionTime;
  @override
  String get imagePath1;
  @override
  String get imagePath2;
  @override
  String get recordName1;
  @override
  String get recordName2;
  @override
  double get similarity;
  @override
  String get imageType;
  @override
  SimilarityLevel get level;
  @override
  String get status;
  @override
  String? get notes;
  @override
  String? get reviewedBy;
  @override
  DateTime? get reviewedAt;
  @override
  @JsonKey(ignore: true)
  _$$DetectionResultImplCopyWith<_$DetectionResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectionSession _$DetectionSessionFromJson(Map<String, dynamic> json) {
  return _DetectionSession.fromJson(json);
}

/// @nodoc
mixin _$DetectionSession {
  String get id => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  String get detectionType => throw _privateConstructorUsedError;
  Map<String, dynamic> get config => throw _privateConstructorUsedError;
  int get totalComparisons => throw _privateConstructorUsedError;
  int get foundIssues => throw _privateConstructorUsedError;
  List<DetectionResult> get results => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DetectionSessionCopyWith<DetectionSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionSessionCopyWith<$Res> {
  factory $DetectionSessionCopyWith(
          DetectionSession value, $Res Function(DetectionSession) then) =
      _$DetectionSessionCopyWithImpl<$Res, DetectionSession>;
  @useResult
  $Res call(
      {String id,
      DateTime startTime,
      DateTime? endTime,
      String detectionType,
      Map<String, dynamic> config,
      int totalComparisons,
      int foundIssues,
      List<DetectionResult> results,
      String status});
}

/// @nodoc
class _$DetectionSessionCopyWithImpl<$Res, $Val extends DetectionSession>
    implements $DetectionSessionCopyWith<$Res> {
  _$DetectionSessionCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? detectionType = null,
    Object? config = null,
    Object? totalComparisons = null,
    Object? foundIssues = null,
    Object? results = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      startTime: null == startTime ? _value.startTime : startTime as DateTime,
      endTime: freezed == endTime ? _value.endTime : endTime as DateTime?,
      detectionType: null == detectionType ? _value.detectionType : detectionType as String,
      config: null == config ? _value.config : config as Map<String, dynamic>,
      totalComparisons: null == totalComparisons ? _value.totalComparisons : totalComparisons as int,
      foundIssues: null == foundIssues ? _value.foundIssues : foundIssues as int,
      results: null == results ? _value.results : results as List<DetectionResult>,
      status: null == status ? _value.status : status as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectionSessionImplCopyWith<$Res>
    implements $DetectionSessionCopyWith<$Res> {
  factory _$$DetectionSessionImplCopyWith(_$DetectionSessionImpl value,
          $Res Function(_$DetectionSessionImpl) then) =
      __$$DetectionSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime startTime,
      DateTime? endTime,
      String detectionType,
      Map<String, dynamic> config,
      int totalComparisons,
      int foundIssues,
      List<DetectionResult> results,
      String status});
}

/// @nodoc
class __$$DetectionSessionImplCopyWithImpl<$Res>
    extends _$DetectionSessionCopyWithImpl<$Res, _$DetectionSessionImpl>
    implements _$$DetectionSessionImplCopyWith<$Res> {
  __$$DetectionSessionImplCopyWithImpl(_$DetectionSessionImpl _value,
      $Res Function(_$DetectionSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? detectionType = null,
    Object? config = null,
    Object? totalComparisons = null,
    Object? foundIssues = null,
    Object? results = null,
    Object? status = null,
  }) {
    return _then(_$DetectionSessionImpl(
      id: null == id ? _value.id : id as String,
      startTime: null == startTime ? _value.startTime : startTime as DateTime,
      endTime: freezed == endTime ? _value.endTime : endTime as DateTime?,
      detectionType: null == detectionType ? _value.detectionType : detectionType as String,
      config: null == config ? _value._config : config as Map<String, dynamic>,
      totalComparisons: null == totalComparisons ? _value.totalComparisons : totalComparisons as int,
      foundIssues: null == foundIssues ? _value.foundIssues : foundIssues as int,
      results: null == results ? _value._results : results as List<DetectionResult>,
      status: null == status ? _value.status : status as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectionSessionImpl implements _DetectionSession {
  const _$DetectionSessionImpl(
      {required this.id,
      required this.startTime,
      this.endTime,
      required this.detectionType,
      required final Map<String, dynamic> config,
      required this.totalComparisons,
      required this.foundIssues,
      required final List<DetectionResult> results,
      this.status = 'completed'})
      : _config = config,
        _results = results;

  factory _$DetectionSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectionSessionImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  @override
  final String detectionType;
  final Map<String, dynamic> _config;
  @override
  Map<String, dynamic> get config {
    if (_config is EqualUnmodifiableMapView) return _config;
    return EqualUnmodifiableMapView(_config);
  }

  @override
  final int totalComparisons;
  @override
  final int foundIssues;
  final List<DetectionResult> _results;
  @override
  List<DetectionResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    return EqualUnmodifiableListView(_results);
  }

  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'DetectionSession(id: $id, startTime: $startTime, endTime: $endTime, detectionType: $detectionType, config: $config, totalComparisons: $totalComparisons, foundIssues: $foundIssues, results: $results, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.detectionType, detectionType) ||
                other.detectionType == detectionType) &&
            const DeepCollectionEquality().equals(other._config, _config) &&
            (identical(other.totalComparisons, totalComparisons) ||
                other.totalComparisons == totalComparisons) &&
            (identical(other.foundIssues, foundIssues) ||
                other.foundIssues == foundIssues) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      startTime,
      endTime,
      detectionType,
      const DeepCollectionEquality().hash(_config),
      totalComparisons,
      foundIssues,
      const DeepCollectionEquality().hash(_results),
      status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionSessionImplCopyWith<_$DetectionSessionImpl> get copyWith =>
      __$$DetectionSessionImplCopyWithImpl<_$DetectionSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectionSessionImplToJson(this);
  }
}

abstract class _DetectionSession implements DetectionSession {
  const factory _DetectionSession(
      {required final String id,
      required final DateTime startTime,
      final DateTime? endTime,
      required final String detectionType,
      required final Map<String, dynamic> config,
      required final int totalComparisons,
      required final int foundIssues,
      required final List<DetectionResult> results,
      final String status}) = _$DetectionSessionImpl;

  factory _DetectionSession.fromJson(Map<String, dynamic> json) =
      _$DetectionSessionImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get startTime;
  @override
  DateTime? get endTime;
  @override
  String get detectionType;
  @override
  Map<String, dynamic> get config;
  @override
  int get totalComparisons;
  @override
  int get foundIssues;
  @override
  List<DetectionResult> get results;
  @override
  String get status;
  @override
  @JsonKey(ignore: true)
  _$$DetectionSessionImplCopyWith<_$DetectionSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
} 