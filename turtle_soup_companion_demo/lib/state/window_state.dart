// [文件7]
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';

// V7.1 (模块3) 最终版:
// 根据 V7.1 规范, 不再需要 'ref'
final windowStateProvider =
    StateNotifierProvider<WindowStateNotifier, WindowState>(
  (ref) => WindowStateNotifier(),
);

/// (模块3) V7.1: 窗口状态 (normal / minimized) 的 StateNotifier
///
/// V7.1 职责简化: 仅管理窗口状态。
/// (V7.1 规范已将 "切换到 Idle_Action" 的逻辑移至模块 1: WindowService)
class WindowStateNotifier extends StateNotifier<WindowState> {
  WindowStateNotifier()
      : super(WindowState.normal); // V7.1 (2.7.5): 总是以 "普通状态" 启动

  /// (模块1 & 6 调用) V7.1 (2.7.3): 切换到最小化
  void minimize() {
    state = WindowState.minimized;
  }

  /// (模块1 & 6 调用) V7.1 (2.7.3): 切换到最大化 (普通)
  void maximize() {
    state = WindowState.normal;
  }
}
