// (模块 3) V6.0 (2.7.5): 设置持久化服务
// 职责: 封装 SharedPreferences 的读写逻辑

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turtle_soup_companion_demo/state/settings_state.dart';

// --- Keys ---
const String _kMasterVolume = 'settings_masterVolume';
const String _kTtsVolume = 'settings_ttsVolume';
const String _kPetSize = 'settings_petSize';
const String _kFontSize = 'settings_fontSize';
const String _kIsTtsEnabled = 'settings_isTtsEnabled';
const String _kIsSoundEffectsEnabled = 'settings_isSoundEffectsEnabled';
const String _kIsClickThroughEnabled = 'settings_isClickThroughEnabled';

/// (模块 3) 注册为 Provider
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(),
);

class SettingsService {
  /// (模块 3) V6.0 (2.7.5): 从本地加载设置
  Future<SettingsState> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      masterVolume: prefs.getDouble(_kMasterVolume) ?? 1.0,
      ttsVolume: prefs.getDouble(_kTtsVolume) ?? 1.0,
      petSize: prefs.getDouble(_kPetSize) ?? 1.0,
      fontSize: prefs.getDouble(_kFontSize) ?? 14.0,
      isTtsEnabled: prefs.getBool(_kIsTtsEnabled) ?? true,
      isSoundEffectsEnabled: prefs.getBool(_kIsSoundEffectsEnabled) ?? true,
      isClickThroughEnabled: prefs.getBool(_kIsClickThroughEnabled) ?? true,
    );
  }

  /// (模块 3) V6.0 (2.7.5): 保存设置到本地
  Future<void> saveSettings(SettingsState settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMasterVolume, settings.masterVolume);
    await prefs.setDouble(_kTtsVolume, settings.ttsVolume);
    await prefs.setDouble(_kPetSize, settings.petSize);
    await prefs.setDouble(_kFontSize, settings.fontSize);
    await prefs.setBool(_kIsTtsEnabled, settings.isTtsEnabled);
    await prefs.setBool(
        _kIsSoundEffectsEnabled, settings.isSoundEffectsEnabled);
    await prefs.setBool(
        _kIsClickThroughEnabled, settings.isClickThroughEnabled);
  }
}
