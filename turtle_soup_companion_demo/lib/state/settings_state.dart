// (模块 3) V6.0 (2.7.4): 设置状态
// 职责: 存储所有设置面板的选项, 并自动调用持久化服务

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/services/settings_service.dart';

/// (模块 3) V6.0 (2.7.4): 设置状态的不可变数据模型
@immutable
class SettingsState {
  // V6.0 (2.7.4) 规范:
  final double masterVolume;
  final double ttsVolume;
  final double petSize; // 0.5x - 2.0x
  final double fontSize; // 12pt - 24pt
  final bool isTtsEnabled;
  final bool isSoundEffectsEnabled;
  final bool isClickThroughEnabled; // V5.0 核心穿透逻辑

  const SettingsState({
    this.masterVolume = 1.0,
    this.ttsVolume = 1.0,
    this.petSize = 1.0,
    this.fontSize = 14.0,
    this.isTtsEnabled = true,
    this.isSoundEffectsEnabled = true,
    this.isClickThroughEnabled = true,
  });

  SettingsState copyWith({
    double? masterVolume,
    double? ttsVolume,
    double? petSize,
    double? fontSize,
    bool? isTtsEnabled,
    bool? isSoundEffectsEnabled,
    bool? isClickThroughEnabled,
  }) {
    return SettingsState(
      masterVolume: masterVolume ?? this.masterVolume,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      petSize: petSize ?? this.petSize,
      fontSize: fontSize ?? this.fontSize,
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      isSoundEffectsEnabled:
          isSoundEffectsEnabled ?? this.isSoundEffectsEnabled,
      isClickThroughEnabled:
          isClickThroughEnabled ?? this.isClickThroughEnabled,
    );
  }
}

/// (模块 3) V6.0: 注册为 StateNotifierProvider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

/// (模块 3) V6.0: 设置状态的 Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(const SettingsState()) {
    // 启动时, 立即异步加载本地设置
    _load();
  }

  Future<void> _load() async {
    state = await _settingsService.loadSettings();
  }

  // --- 公共方法 (由 模块6 设置面板调用) ---

  Future<void> setMasterVolume(double value) async {
    state = state.copyWith(masterVolume: value);
    await _settingsService.saveSettings(state);
  }

  Future<void> setTtsVolume(double value) async {
    state = state.copyWith(ttsVolume: value);
    await _settingsService.saveSettings(state);
  }

  Future<void> setPetSize(double value) async {
    state = state.copyWith(petSize: value);
    await _settingsService.saveSettings(state);
  }

  Future<void> setFontSize(double value) async {
    state = state.copyWith(fontSize: value);
    await _settingsService.saveSettings(state);
  }

  Future<void> setIsTtsEnabled(bool value) async {
    state = state.copyWith(isTtsEnabled: value);
    await _settingsService.saveSettings(state);
  }

  Future<void> setIsSoundEffectsEnabled(bool value) async {
    state = state.copyWith(isSoundEffectsEnabled: value);
    await _settingsService.saveSettings(state);
  }

  /// V6.0 (2.7.4) 核心: 切换点击穿透总开关
  Future<void> setIsClickThroughEnabled(bool value) async {
    state = state.copyWith(isClickThroughEnabled: value);
    await _settingsService.saveSettings(state);

    // (V6.0 备注: 模块2 PlatformService 会在下次 hover/exit 时
    // 自动读取这个新值, 无需在此处强制调用)
  }
}
