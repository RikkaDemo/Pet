// [文件8]
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_constants.dart';
// V7.1 (2.7.3) 核心依赖: 角色状态
import 'package:turtle_soup_companion_demo/state/character_state.dart';
// V7.1 核心依赖: 窗口状态 (修复 Error 1, 2)
import 'package:turtle_soup_companion_demo/state/window_state.dart';
import 'package:window_manager/window_manager.dart';

// (模块1) 将 WindowService 注册为 Riverpod Provider
// V7.1 修复: 这个 Provider *只* 在这个文件中定义
final windowServiceProvider = Provider<WindowService>((ref) {
  return WindowService(ref);
});

/// (模块1) 窗口服务
/// 职责: 初始化窗口, 并提供 V7.1 核心的 minimize/maximize 方法
class WindowService {
  final Ref _ref;
  WindowService(this._ref);

  final WindowManager _windowManager = WindowManager.instance;
  final ScreenRetriever _screenRetriever = ScreenRetriever.instance;

  /// V7.1 (模块1) 核心: 初始化窗口
  /// V7.1 需求 (2.7.5): 总是以 "普通状态" (800x600, 居中) 启动
  Future<void> init() async {
    // 1. 确保 window_manager 初始化
    await _windowManager.ensureInitialized();

    // 2. 定义 V7.1 启动窗口选项
    const WindowOptions windowOptions = WindowOptions(
      size: kNormalSize, // V7.1 (2.7.5): 总是 800x600
      center: true, // V7.1 (2.7.5): 总是 居中
      backgroundColor: Colors.transparent, // V7.1 (2.1): 背景透明
      skipTaskbar: false, // 在任务栏上显示图标
      titleBarStyle: TitleBarStyle.hidden, // V7.1 (2.1): 无系统标题栏
    );

    // 3. 等待窗口准备就绪 - 修复：确保窗口正确显示
    await _windowManager.waitUntilReadyToShow(windowOptions, () async {
      await _windowManager.setAsFrameless(); // V7.1 (2.1): 无边框
      await _windowManager.setBackgroundColor(Colors.transparent); // 再次确认透明
      await _windowManager.setAlwaysOnTop(true); // V7.1 (2.1): 置顶显示

      // V7.1 Fix: 确保窗口显示并获取焦点
      await _windowManager.show();
      await _windowManager.focus();

      if (kDebugMode) {
        print("Window initialized and shown successfully");
      }
    });
  }

  /// V7.1 (模块1) 核心: 切换到最小化状态 (400x300, 右下角)
  /// (由 模块6 的菜单调用)
  Future<void> minimizeWindow() async {
    // 1. 获取主显示器
    final primaryDisplay = await _screenRetriever.getPrimaryDisplay();

    // 2. (V7.1) 计算右下角位置 (在任务栏上方)
    final visiblePos = primaryDisplay.visiblePosition ?? Offset.zero;
    final visibleSize = primaryDisplay.visibleSize ?? primaryDisplay.size;

    // 'workArea' 是排除了任务栏等系统UI的可视工作区
    final workArea = Rect.fromLTWH(
      visiblePos.dx,
      visiblePos.dy,
      visibleSize.width,
      visibleSize.height,
    );

    // 现在的 'workArea.left', 'workArea.width' 等属性就是正确的了
    final newX = workArea.left + workArea.width - kMinimizedSize.width;
    final newY = workArea.top + workArea.height - kMinimizedSize.height;

    // 3. 应用窗口变化 (V7.1 规范 2.7.3)
    await _windowManager.setPosition(Offset(newX, newY));
    await _windowManager.setSize(kMinimizedSize);

    // 4. (V7.1) 核心: 更新全局状态 (模块3) (修复 Error 1)
    _ref.read(windowStateProvider.notifier).minimize();

    // 5. (V7.1 核心 2.7.3) 新增:
    // 立即打断当前动画 (如 Walk/Happy) 并强制切换到 Idle_Action
    _ref.read(characterStateProvider.notifier).setIdleAction();
  }

  /// V7.1 (模块1) 核心: 切换到普通状态 (800x600, 居中)
  /// (由 模块6 的菜单调用)
  Future<void> maximizeWindow() async {
    // 1. 应用窗口变化 (V7.1 规范 2.7.3)
    await _windowManager.setSize(kNormalSize);
    await _windowManager.center(); // V7.1 (2.7.3): "调用 window_manager.center()"

    // 2. (V7.1) 核心: 更新全局状态 (模块3) (修复 Error 2)
    _ref.read(windowStateProvider.notifier).maximize();

    // 3. (V7.1 核心 2.7.3) 新增:
    // 立即打断当前动画 (如 Walk/Happy) 并强制切换到 Idle_Action
    _ref.read(characterStateProvider.notifier).setIdleAction();
  }
}
