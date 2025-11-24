// lib/features/settings/settings_dialog.dart
// (模块 6) V7.2.4 (2.7.4): 完整设置面板

import 'dart:io'; // V7.2.4 (模块 6) 退出程序
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';
import 'package:turtle_soup_companion_demo/state/providers.dart';

/// (模块 6) V7.2.4 (2.7.4): 完整设置面板
class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (V7.2.4 模块 6) 监听状态 (用于 UI 实时更新)
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    // V7.1 (2.7.2) 规范:
    final windowState = ref.watch(windowStateProvider);
    final isNormal = windowState == WindowState.normal;

    // V7.1 (2.7.3) 规范: 检查 Offline 状态 (用于喂食)
    final isOffline =
        ref.watch(characterStateProvider) == CharacterState.offline;

    return AlertDialog(
      title: const Text('⚙️ 设置'),
      // V7.2.4 (模块 6) 使其可滚动, 防止溢出
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 滑块 (V7.2.4 规范 2.7.4) ---
            _SettingsSlider(
              label: '🔊 主音量:',
              value: settings.masterVolume,
              onChanged: (val) => settingsNotifier.setMasterVolume(val),
            ),
            _SettingsSlider(
              label: '🗣️ 语音音量:',
              value: settings.ttsVolume,
              onChanged: (val) => settingsNotifier.setTtsVolume(val),
            ),
            _SettingsSlider(
              label: '📏 桌宠大小:',
              value: settings.petSize,
              min: 0.5,
              max: 2.0,
              divisions: 15, // (2.0 - 0.5) / 0.1
              labelSuffix: 'x',
              onChanged: (val) => settingsNotifier.setPetSize(val),
            ),
            _SettingsSlider(
              label: '🔤 字体大小:',
              value: settings.fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              labelSuffix: 'pt',
              onChanged: (val) => settingsNotifier.setFontSize(val),
            ),

            const Divider(),

            // --- 复选框 (V7.2.4 规范 2.7.4) ---
            _SettingsCheckbox(
              label: '启用 TTS 语音',
              value: settings.isTtsEnabled,
              onChanged: (val) => settingsNotifier.setIsTtsEnabled(val!),
            ),
            _SettingsCheckbox(
              label: '启用音效',
              value: settings.isSoundEffectsEnabled,
              onChanged: (val) =>
                  settingsNotifier.setIsSoundEffectsEnabled(val!),
            ),
            _SettingsCheckbox(
              label: '启用点击穿透', // V7.2.4 核心
              value: settings.isClickThroughEnabled,
              onChanged: (val) {
                settingsNotifier.setIsClickThroughEnabled(val!);

                // (V7.2.4 模块 6) 核心: 立即应用穿透
                // (V7.2.4 模块 6) 修正: PlatformService 会在
                // 下次 onHover/onExit 时自动读取新值,
                // 但如果鼠标当前不在桌宠上 (即已穿透),
                // 我们需要立即切换状态。
                final platformService = ref.read(platformServiceProvider);
                if (val == true) {
                  // (V7.2.4 模块 6) 切换到穿透
                  // (假设鼠标不在桌宠上)
                  platformService.setClickThrough();
                } else {
                  // (V7.2.4 模块 6) 切换到不穿透
                  platformService.setHitTest();
                }
              },
            ),

            const Divider(),

            // --- 宠物控制 (V7.2.4 规范 2.7.4) ---
            const Text('宠物控制', style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              // V7.1 (2.7.3) 规范: Offline 时禁用
              onPressed: isOffline
                  ? null
                  : () {
                      ref
                          .read(characterStateProvider.notifier)
                          .setState(CharacterState.onFeed);
                      // (V7.2.4 模块 6) 关闭对话框
                      Navigator.of(context).pop();
                    },
              child: const Text('喂食'),
            ),

            const Divider(),

            // --- 窗口控制 (V7.2.4 规范 2.7.4) ---
            const Text('窗口控制', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: [
                // 1. 最小化/最大化
                ElevatedButton(
                  onPressed: () {
                    final windowService = ref.read(windowServiceProvider);
                    if (isNormal) {
                      windowService.minimizeWindow();
                    } else {
                      windowService.maximizeWindow();
                    }
                    // (V7.2.4 模块 6) 关闭对话框
                    Navigator.of(context).pop();
                  },
                  child: Text(isNormal ? '最小化' : '最大化'),
                ),
                // 2. 关闭程序
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: () {
                    exit(0); // V7.1 (2.7.3)
                  },
                  child:
                      const Text('关闭程序', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // V7.2.4 (模块 6) 规范 (2.7.4): 确定/取消
        // (V7.2.4 备注: 由于 Riverpod 和设置是即时保存的,
        // "取消" 按钮没有意义, "确定" 仅用于关闭对话框)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // "取消"
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // "确定"
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

// (V7.2.4 模块 6) 辅助 Widget (滑块)
class _SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String labelSuffix;

  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.labelSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    String displayLabel;
    if (divisions != null) {
      displayLabel = value.toStringAsFixed(1);
    } else {
      displayLabel = (value * 100).toStringAsFixed(0);
    }

    return Row(
      children: [
        Text(label),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '$displayLabel$labelSuffix',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// (V7.2.4 模块 6) 辅助 Widget (复选框)
class _SettingsCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _SettingsCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        // (V7.2.4 模块 6) 使标签也可点击
        Expanded(
          child: InkWell(
            onTap: () => onChanged(!value),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
