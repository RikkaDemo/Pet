//character_animator
// (模块 5) V7.1 核心: 角色动画器
// (V7.2 修复 7: 修复拖拽 "闪烁" (动画重启) 问题)
// (V7.2.5 修复: 修复 OnDrag/PushBoundary 快速切换导致的 "红框" 闪烁)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';
import 'package:turtle_soup_companion_demo/state/providers.dart';

// V7.2.1 (2.2.1) 规范: 从 app_constants.dart 导入
import 'package:turtle_soup_companion_demo/core/utils/app_constants.dart';

// (V7.2.1) 移除本地常量
// const double kPetWidth = 300.0;
// const double kPetHeight = 400.0;

// (V7.1 占位符) 帧率 (FPS)
const int _kFps = 20;

class AnimationData {
  final String path;
  final int frameCount;
  final bool loop;

  AnimationData(this.path, this.frameCount, {this.loop = false});
}

// V7.1 (4.) 资源: 定义所有状态的动画资源 (已按用户要求更新 V7.1 帧数)
final Map<CharacterState, AnimationData> _animationMap = {
  // V7.1 (2.6.2) 状态链: 0/1 分 (播放 2 套)
  CharacterState.idle_emotion:
      AnimationData('assets/animations/idle_emotion', 12), // 12 帧
  // V7.1 (2.6.2) 状态链: 2/3 分 (播放 2 套)
  CharacterState.happy: AnimationData('assets/animations/happy', 37), // 37 帧
  // V7.1 (2.6.2) 状态链: 胜利 (播放 1 套)
  CharacterState.shock: AnimationData('assets/animations/shock', 36), // 36 帧

  // V7.1 (P5) 自主: 待机动动作
  CharacterState.idle_action:
      AnimationData('assets/animations/idle_action', 12, loop: true), // 12 帧
  // V7.1 (P5) 自主: 散步
  CharacterState.walk:
      AnimationData('assets/animations/walk', 11, loop: true), // 11 帧

  // V7.1 (P1-P3) 交互: (V7.1 规范: 文件夹名为 'click', 'drag', 'feed')
  CharacterState.onDrag:
      AnimationData('assets/animations/drag', 35, loop: true), // 35 帧
  CharacterState.onClick: AnimationData('assets/animations/click', 47), // 47 帧
  CharacterState.onFeed: AnimationData('assets/animations/feed', 24), // 24 帧

  // (V7.2 修复 A: 设为 'loop: true' 解决闪烁问题)
  CharacterState.pushBoundary:
      AnimationData('assets/animations/push_boundary', 23, loop: true), // 23 帧

  // V7.1 (3.3) 离线: (使用 idle_action 11 帧作为占位符)
  CharacterState.offline:
      AnimationData('assets/animations/idle_action', 12, loop: true),
};

/// (模块 5) V7.1 核心: 动画器 (状态机实现)
class CharacterAnimator extends ConsumerStatefulWidget {
  const CharacterAnimator({super.key});

  @override
  ConsumerState<CharacterAnimator> createState() => _CharacterAnimatorState();
}

class _CharacterAnimatorState extends ConsumerState<CharacterAnimator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // V7.1 (2.6.2) 核心: 状态链计数器
  int _animationLoopCount = 0;
  CharacterState _currentState = CharacterState.idle_action;

  // V7.1 (2.6.2) 修正: 用于区分 Happy 来源 (V7.1 最终方案 2)
  bool _isHappyFromShock = false;

  // V7.1 (4.) 资源: 帧图像
  int _currentFrame = 1;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000 ~/ _kFps), // 默认
    );

    // 帧更新
    _controller.addListener(() {
      // (V7.1 健壮性: 确保 mounted 状态)
      if (!mounted) return;
      final data = _animationMap[_currentState];
      if (data == null) return;

      int frame = (_controller.value * (data.frameCount - 1)).floor() + 1;
      frame = frame.clamp(1, data.frameCount);
      if (frame != _currentFrame) {
        setState(() {
          _currentFrame = frame;
        });
      }
    });

    // V7.1 (2.6.2) 核心: 动画状态 (状态链)
    _controller.addStatusListener(_onAnimationStatusChanged);

    // V7.1 启动: 播放初始状态
    _playAnimationForState(CharacterState.idle_action);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  /// V7.1 (2.6.2) 核心: 监听状态机 (来自 模块 3)
  void _listenToStateProvider() {
    // (V7.1 健壮性: 确保 mounted 状态)
    if (!mounted) return;

    final newState = ref.watch(characterStateProvider);

    // (V7.2 修复 7: 仅在状态 *真的* 改变时才播放)
    if (newState != _currentState) {
      if (kDebugMode) {
        print("[Animator] V7.1 State Change: $_currentState -> $newState");
      }
      // V7.1 核心: 切换动画
      _playAnimationForState(newState);
    }
  }

  /// V7.1 (2.6.2) 核心: 播放新动画 (重置 V7.1 计数器)
  /// (V7.2 修复 7: 增加防抖逻辑)
  /// (V7.2.5 修复: 修复拖拽闪烁)
  void _playAnimationForState(CharacterState newState) {
    // (V7.1 健壮性: 确保 mounted 状态)
    if (!mounted) return;

    // (V7.2 修复 7)
    // 检查是否只是在 OnDrag 和 PushBoundary (两个都是循环) 之间切换
    bool isThrashingDrag = (newState == CharacterState.onDrag &&
            _currentState == CharacterState.pushBoundary) ||
        (newState == CharacterState.pushBoundary &&
            _currentState == CharacterState.onDrag);

    // V7.1 (2.6.2) 修正: 重置 Happy 状态标记
    if (newState != CharacterState.happy) {
      _isHappyFromShock = false;
    }

    final data = _animationMap[newState];
    if (data == null) {
      if (kDebugMode) {
        print("[Animator] V7.1 Error: 找不到状态 $newState 对应的动画数据。");
      }
      return;
    }

    // V7.1 核心: 重置状态链
    setState(() {
      _currentState = newState;

      // (V7.2 修复 7 / V7.2.5 修复 闪烁)
      if (!isThrashingDrag) {
        _animationLoopCount = 0;
        _currentFrame = 1;
      } else {
        // --- BUG FIX (V7.2.5) ---
        // 当在 OnDrag 和 PushBoundary 之间快速切换 (isThrashingDrag) 时,
        // 我们保留了 _controller.value, 但 _currentFrame 必须
        // 立即被重新计算以匹配 *新* 状态 (newState) 的帧数。
        // 否则, build() 会在 listener 运行前尝试使用一个无效的帧号 (例如 30)
        // 来渲染一个只有 23 帧的动画, 导致红框。
        if (_controller.value > 0.0) {
          // 检查值是否有效
          final newFrameCount = data.frameCount;
          if (newFrameCount > 1) {
            int newFrame =
                (_controller.value * (newFrameCount - 1)).floor() + 1;
            _currentFrame = newFrame.clamp(1, newFrameCount);
          } else {
            _currentFrame = 1; // 新动画只有1帧
          }
        } else {
          // (如果 controller value 是 0.0, 可能是刚开始, 设为 1 是安全的)
          _currentFrame = 1;
        }
        // --- BUG FIX END ---
      }
    });

    final frameCount = data.frameCount > 0 ? data.frameCount : 1;
    final durationMs = (frameCount / _kFps) * 1000;
    _controller.duration = Duration(milliseconds: durationMs.round());

    if (data.loop) {
      // (V7.2 修复 7) 如果动画已在运行且只是拖拽切换，不要调用 repeat()
      if (!_controller.isAnimating || !isThrashingDrag) {
        _controller.repeat();
      }
    } else {
      _controller.forward(from: 0.0);
    }
  }

  /// V7.1 (2.6.2) 核心: 状态链 自动切换
  Future<void> _onAnimationStatusChanged(AnimationStatus status) async {
    // (V7.1 健壮性: 确保 mounted 状态)
    if (!mounted) return;

    // 仅在非循环动画播放完毕时触发
    if (status != AnimationStatus.completed) return;

    final data = _animationMap[_currentState];
    if (data == null || data.loop) return;

    // V7.1 状态链 计数器
    _animationLoopCount++;

    final notifier = ref.read(characterStateProvider.notifier);

    // V7.1 (2.6.2) 逻辑:
    switch (_currentState) {
      // V7.1 (2.6.2) 修正: Shock -> Happy (1 套)
      case CharacterState.shock:
        if (kDebugMode) {
          print(
              "[Animator] V7.1 Chain (Fixed): Shock (x1) -> Happy (Setting flag)");
        }
        _isHappyFromShock = true;
        notifier.setState(CharacterState.happy);
        break;

      // V7.1 (2.6.2): 0/1 分 (播放 2 套)
      case CharacterState.idle_emotion:
        if (_animationLoopCount >= 2) {
          if (kDebugMode) {
            print("[Animator] V7.1 Chain: Idle_Emotion (x2) -> Idle_Action");
          }
          notifier.setIdleAction();
        } else {
          _controller.forward(from: 0.0);
        }
        break;

      // V7.1 (2.6.2) 修正: Happy (区分 1 套 还是 2 套)
      case CharacterState.happy:
        if (_isHappyFromShock) {
          // 路径 B (游戏胜利): V7.1 (2.2.2 P4) 要求 1 套
          if (kDebugMode) {
            print(
                "[Animator] V7.1 Chain (Fixed): Happy (x1, from Shock) -> Idle_Action");
          }
          notifier.setIdleAction();
        } else {
          // 路径 A (2/3分): V7.1 (2.6.2) 要求 2 套
          if (_animationLoopCount >= 2) {
            if (kDebugMode) {
              print(
                  "[Animator] V7.1 Chain (Fixed): Happy (x2, from Score) -> Idle_Action");
            }
            notifier.setIdleAction();
          } else {
            _controller.forward(from: 0.0);
          }
        }
        break;

      // V7.1 (2.2.2) P2/P3: (播放 1 套)
      case CharacterState.onClick:
      case CharacterState.onFeed:
        if (kDebugMode) {
          print(
              "[Animator] V7.1 Chain: Interaction $_currentState (x1) -> Idle_Action");
        }
        notifier.setIdleAction();
        break;

      // (V7.2 MODIFIED)
      // V7.2 (6.2) 核心: 移除 'PushBoundary'
      // V7.2 修复 A: PushBoundary 现在是循环动画，不会进入此 case
      // case CharacterState.pushBoundary: (REMOVED)

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _listenToStateProvider();

    final data = _animationMap[_currentState];
    if (data == null) {
      // (V7.2 修复 6) 确保错误占位符使用 kPetWidth/Height (V7.2.1: 从 app_constants 导入)
      return const SizedBox(
        width: kPetWidth,
        height: kPetHeight,
        child:
            Text('Error: State missing', style: TextStyle(color: Colors.red)),
      );
    }

    // VSetting up the correct file paths
    // V7.1 最终修正:
    // 我们必须使用文件夹名 (如 'click') 作为文件前缀,
    // 而不是 Enum 名 (如 'onClick')。
    final String folderName =
        data.path.split('/').last; // <-- V7.1 最终修正 (获取 'click')

    final framePadded = _currentFrame.toString().padLeft(3, '0');
    // V7.1 最终修正: 使用 folderName 作为前缀
    final imagePath = '${data.path}/${folderName}_$framePadded.png';

    // V7.1 (3.3) Offline 逻辑: 离线时 50% 透明度
    final isOffline = _currentState == CharacterState.offline;

    return Opacity(
      opacity: isOffline ? 0.5 : 1.0,
      child: Image.asset(
        imagePath,
        // (V7.2 修复 5: 移除 width/height, 解决 变形/交互错位 问题)
        // width: kPetWidth,  <-- REMOVED
        // height: kPetHeight, <-- REMOVED
        filterQuality: FilterQuality.none,

        // (V7.2 修复 6: 设为 'fill' 解决 400x200 变形问题)
        fit: BoxFit.fill,

        // (V7.2 修复 6: 设回 'true' 消除 "闪烁" (Flicker))
        // V7.2.1 (8.1) 规范: 防闪烁处理
        gaplessPlayback: true,

        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print("[Animator] V7.1 Error: Missing asset: $imagePath");
          }
          return Container(
            // (V7.2 修复 5) 错误占位符也移除硬编码尺寸
            // width: kPetWidth,
            // height: kPetHeight,
            color: Colors.red.withAlpha(128),
            child: Text(
              '$folderName\n(Missing $framePadded)',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}
