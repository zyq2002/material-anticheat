import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 车牌过滤状态
class LicensePlateFilterState {
  final String? currentFilter;
  final bool isActive;

  const LicensePlateFilterState({
    this.currentFilter,
    this.isActive = false,
  });

  LicensePlateFilterState copyWith({
    String? currentFilter,
    bool? isActive,
  }) {
    return LicensePlateFilterState(
      currentFilter: currentFilter ?? this.currentFilter,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// 车牌过滤服务
class LicensePlateFilterService extends StateNotifier<LicensePlateFilterState> {
  LicensePlateFilterService() : super(const LicensePlateFilterState());

  /// 设置车牌过滤
  void setFilter(String licensePlate) {
    state = state.copyWith(
      currentFilter: licensePlate,
      isActive: true,
    );
  }

  /// 清除过滤
  void clearFilter() {
    state = const LicensePlateFilterState();
  }

  /// 检查记录是否匹配过滤条件
  bool matchesFilter(Map<String, dynamic> recordData) {
    if (!state.isActive || state.currentFilter == null) {
      return true;
    }

    final licensePlate = recordData['licensePlate'] as String? ?? '';
    return licensePlate.toLowerCase().contains(state.currentFilter!.toLowerCase());
  }
}

/// 车牌过滤 Provider
final licensePlateFilterProvider = StateNotifierProvider<LicensePlateFilterService, LicensePlateFilterState>(
  (ref) => LicensePlateFilterService(),
); 