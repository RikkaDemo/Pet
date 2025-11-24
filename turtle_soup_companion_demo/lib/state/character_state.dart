// (模块 3) V7.1 (2.6.2): 角色状态机
// 职责: 存储 V7.1 精细化的单一互斥状态 (CharacterState)
// (V7.2.4 MODIFIED)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';

/// (模块 3) V7.1: 注册为 StateNotifierProvider
final characterStateProvider =
    StateNotifierProvider<CharacterStateNotifier, CharacterState>(
  (ref) => CharacterStateNotifier(),
);

/// (模块 3) V7.1: 角色状态 Notifier
class CharacterStateNotifier extends StateNotifier<CharacterState> {
  CharacterStateNotifier()
      : super(CharacterState.idle_action); // V7.1 (2.6.1): 启动时为 Idle_Action

  /// (模块 4 调用) V7.1 (2.6.2): 得分-状态关联逻辑
  void setScoreBasedState(int score) {
    // V7.1 (2.6.2) 优先级:
    // (V7.2.4) OnDrag/PushBoundary 现在由 V7.2.4 逻辑处理
    if (state == CharacterState.onDrag ||
        state == CharacterState.onFeed ||
        state == CharacterState.onClick ||
        state == CharacterState.pushBoundary ||
        state == CharacterState.shock) {
      return;
    }

    if (score == 0 || score == 1) {
      // V7.1 (2.6.2): 0/1 分 -> 强制切换到 Idle_Emotion
      state = CharacterState.idle_emotion;
    } else if (score == 2 || score == 3) {
      // V7.1 (2.6.2): 2/3 分 -> 强制切换到 Happy
      state = CharacterState.happy;
    }
  }

  /// (模块 4 调用) V7.1 (2.6.2): 游戏胜利
  void triggerGameSolved() {
    // V7.1 (2.6.2 / 2.2.2) 优先级:
    if (state == CharacterState.onDrag ||
        state == CharacterState.onClick ||
        state == CharacterState.onFeed) {
      return;
    }
    state = CharacterState.shock;
  }

  /// (模块 4/5 调用) V7.1 (3.3): 掉线
  void setOffline() {
    state = CharacterState.offline;
  }

  /// (模块 4/5 调用) V7.1 (3.3): 重连成功
  void setOnline() {
    // 重连后, 恢复到待机动动作
    if (state == CharacterState.offline) {
      state = CharacterState.idle_action;
    }
  }

  /// (模块 1/6 调用) V7.1 (2.7.3) 新增: 强制切换到 Idle_Action
  /// (V7.2.4 MODIFIED)
  void setIdleAction() {
    // V7.2.4 (需求 8) / V7.2 (6.2) 逻辑:
    // 立即切换到 Idle_Action，除非处于 Offline 状态。
    // (V7.2.4) 此函数现在由 V7.2.4 (onPanEnd) 调用
    if (state != CharacterState.offline) {
      state = CharacterState.idle_action;
    }
  }

  /// (模块 5/6 调用) V7.1: 用于交互
  /// (V7.2.4 MODIFIED)
  void setState(CharacterState newState) {
    // V7.1 (2.7.3 / 2.4.2) 交互屏蔽:
    // V7.2.4 (2.4.2.C) 规范: Offline 状态下, 拒绝切换到 OnClick, OnFeed, PushBoundary, OnDrag
    if (state == CharacterState.offline) {
      if (newState == CharacterState.onClick ||
          newState == CharacterState.onFeed ||
          newState == CharacterState.pushBoundary ||
          newState == CharacterState.onDrag) {
        // <-- V7.2.4 (2.4.2.C) 新增
        return; // (V7.1 / V7.2.4) 屏蔽动画
      }
    }

    if (state == newState) return;

    state = newState;
  }
}
