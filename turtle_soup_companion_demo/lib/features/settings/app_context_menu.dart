// // lib/features/settings/app_context_menu.dart
// // (模块 6) V7.1 (2.7.2): 动态上下文菜单
// // (V7.2.6 (Fix) 修复: Linter 警告)

// import 'dart:io'; // V7.2.4 (模块 6) 退出程序
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';
// import 'package:turtle_soup_companion_demo/state/providers.dart';
// // (V7.2.4 模块 6) 导入设置面板
// import 'package:turtle_soup_companion_demo/features/settings/settings_dialog.dart';

// /// (模块 6) V7.1 (2.7.2): 动态上下文菜单
// /// (由 settings_icon.dart 点击时调用)
// Future<void> showAppContextMenu(
//     BuildContext context, Offset tapPosition, WidgetRef ref) async {
//   // V7.1 (2.7.2) 规范: 菜单内容是动态的
//   final windowState = ref.read(windowStateProvider);
//   final isNormal = windowState == WindowState.normal;

//   // V7.1 (2.7.3) 规范: 检查 Offline 状态 (用于喂食)
//   final isOffline = ref.read(characterStateProvider) == CharacterState.offline;

//   // (V7.2.4 模块 6) 获取服务
//   final windowService = ref.read(windowServiceProvider);
//   final characterNotifier = ref.read(characterStateProvider.notifier);

//   await showMenu(
//     context: context,
//     // V7.2.4 (模块 6) 定位:
//     // showMenu 需要一个 RelativeRect, 而不是 Offset
//     position: RelativeRect.fromLTRB(
//       tapPosition.dx,
//       tapPosition.dy,
//       tapPosition.dx + 1, // (V7.2.4 模块 6) 确保 LTRB 矩形有效
//       tapPosition.dy + 1,
//     ),
//     items: [
//       // 1. 设置...
//       // V7.2.6 (Fix): 修复 prefer_const_constructors
//       const PopupMenuItem(
//         value: 'settings',
//         child: Text('设置...'),
//       ),
//       // 2. 喂食
//       PopupMenuItem(
//         value: 'feed',
//         enabled: !isOffline, // V7.1 (2.7.3) 规范: Offline 时禁用
//         child: Text('喂食',
//             style: isOffline ? const TextStyle(color: Colors.grey) : null),
//       ),
//       // 3. 最小化 / 最大化
//       PopupMenuItem(
//         value: 'toggle_window',
//         child: Text(isNormal ? '最小化' : '最大化'),
//       ),
//       // 4. 关闭
//       // V7.2.6 (Fix): 修复 prefer_const_constructors
//       const PopupMenuItem(
//         value: 'close',
//         child: Text('关闭'),
//       ),
//     ],
//     elevation: 8.0,
//   ).then((value) {
//     // V7.1 (2.7.3) 核心: 处理菜单项点击

//     // V7.2.6 (Fix): 修复 use_build_context_synchronously
//     // 必须在 await 之后检查 context 是否仍然挂载
//     if (!context.mounted) return;

//     switch (value) {
//       // 1. 设置...
//       case 'settings':
//         // V7.2.4 (模块 6) 规范 (2.7.4): 弹出设置面板
//         showDialog(
//           context: context,
//           // (V7.2.4 模块 6) 确保设置对话框不会被穿透
//           // (虽然对话框通常会阻止下层交互, 但在透明窗口上最好明确)
//           barrierDismissible: true,
//           builder: (context) => const SettingsDialog(),
//         );
//         break;

//       // 2. 喂食
//       case 'feed':
//         // V7.1 (2.7.3) 规范:
//         if (!isOffline) {
//           characterNotifier.setState(CharacterState.onFeed);
//         }
//         break;

//       // 3. 最小化 / 最大化
//       case 'toggle_window':
//         // V7.1 (2.7.3) 规范:
//         if (isNormal) {
//           windowService.minimizeWindow();
//         } else {
//           windowService.maximizeWindow();
//         }
//         break;

//       // 4. 关闭
//       case 'close':
//         // V7.1 (2.7.3) 规范:
//         exit(0); // (V7.2.4 模块 6) 强制退出
//       // V7.2.6 (Fix) 修复: dead_code
//       // (exit(0) 之后 'break' 永远不会执行, 将其移除)
//       // break;
//     }
//   });
// }
