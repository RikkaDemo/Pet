import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// V5.0 (模块2) 修正: 'package.flutter' 改为 'package:flutter'
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:turtle_soup_companion_demo/state/settings_state.dart';

// (模块2) 将 PlatformService 注册为 Riverpod Provider
final platformServiceProvider = Provider<PlatformService>((ref) {
  return PlatformService(ref);
});

/// (模块2) 平台与穿透服务
/// 职责: 封装所有原生平台 (Windows) 交互, 主要是点击穿透
class PlatformService {
  final Ref _ref;
  PlatformService(this._ref);

  // V5.0 (2.1): 定义一个唯一的平台通道名称
  static const MethodChannel _channel =
      MethodChannel('com.example.turtle_soup_companion/platform_service');

  /// V5.0 (2.1) 核心: 启用点击穿透
  /// (由 模块5 和 模块7 在 onMouseExit 时调用)
  Future<void> setClickThrough() async {
    // V5.0 (2.7.4) 逻辑:
    // 只有当用户在设置中 *启用* 了点击穿透时, 才真正执行穿透
    final bool isMasterSwitchEnabled =
        _ref.read(settingsProvider).isClickThroughEnabled;

    if (!isMasterSwitchEnabled) {
      // 如果总开关是关闭的, 保持窗口可点击, 不执行任何操作
      return;
    }

    try {
      await _channel.invokeMethod('setClickThrough');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        // info - Don't invoke 'print'
        // (V5.0 备注: 此处 print 受 kDebugMode 保护, 符合调试目的)
        print("Failed to set click-through: '${e.message}'.");
      }
    }
  }

  /// V5.0 (2.1) 核心: 取消点击穿透 (使其可交互)
  /// (由 模块5 和 模块7 在 onMouseEnter 时调用)
  Future<void> setHitTest() async {
    // V5.0 (2.7.4) 逻辑:
    // 无论总开关如何, "取消穿透" 总是应该执行,
    // 以确保桌宠和UI面板始终可以被点击。
    try {
      await _channel.invokeMethod('setHitTest');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        // info - Don't invoke 'print'
        // (V5.0 备注: 此处 print 受 kDebugMode 保护, 符合调试目的)
        print("Failed to set hit-test: '${e.message}'.");
      }
    }
  }

  /// (模块2) 初始化
  /// 在 App 启动时被 main.dart 调用
  Future<void> init() async {
    // V5.0 (2.7.4): 根据设置, 初始化窗口的穿透状态
    final bool isMasterSwitchEnabled =
        _ref.read(settingsProvider).isClickThroughEnabled;

    if (isMasterSwitchEnabled) {
      // 默认是启用了穿透, 所以启动时背景应该是透明的
      await setClickThrough();
    } else {
      // 如果用户禁用了穿透, 启动时整个窗口就应该是可点击的
      await setHitTest();
    }
  }
}
