// [文件] lib/app_view.dart
// (V7.2.4 核心修改: 实现 V7.2.4 需求 2 - 拖拽背景移动窗口)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_constants.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';
import 'package:turtle_soup_companion_demo/features/character/character_view.dart';
import 'package:turtle_soup_companion_demo/state/providers.dart';
import 'package:window_manager/window_manager.dart'; // V7.2.4 新增

/// V7.1: 最终的主视图
/// (V7.2.4 修正: 转换为 ConsumerWidget 以便访问 ref)
class AppView extends ConsumerWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (模块1) V7.1 (2.1): 根视图必须是透明的
    return Scaffold(
      // backgroundColor: Colors.transparent, // V7.2.4 确认: 必须透明
      body: Consumer(
        builder: (context, ref, child) {
          // 监听窗口状态 (normal / minimized)
          final winState = ref.watch(windowStateProvider);
          final Size windowSize =
              (winState == WindowState.normal) ? kNormalSize : kMinimizedSize;

          // V7.2.4 (需求 2) 核心:
          // 将根 SizedBox 包装在 GestureDetector 中, 以便
          // 在"关闭穿透"时拖拽背景来移动窗口。
          return GestureDetector(
            // V7.2.4 (需求 2)
            onPanStart: (details) {
              final settings = ref.read(settingsProvider);
              // 仅在"点击穿透"被 *关闭* 时才允许拖拽窗口
              if (settings.isClickThroughEnabled) {
                return;
              }
              // V7.2.4 (需求 2): 拖拽窗口期间, 桌宠保持 Idle_Action
              ref.read(characterStateProvider.notifier).setIdleAction();
              // V7.2.4 (需求 2): 开始拖拽窗口
              windowManager.startDragging();
            },
            child: SizedBox(
              width: windowSize.width,
              height: windowSize.height,
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  // (V7.1) 模块 5: 角色系统
                  CharacterView(),

                  // (V7.1) 模块 7: UI 面板层 (占位符)
                  /* ... */
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
