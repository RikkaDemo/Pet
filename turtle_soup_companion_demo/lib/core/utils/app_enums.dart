// [文件10]
// (模块3) V7.1 (2.1 / 2.2.2): 窗口状态枚举
enum WindowState { normal, minimized }

/// (模块3) V7.1 (2.2.2) 核心重构: 单一且互斥的状态机
///
/// V7.1 规范 (2.2.2) 状态列表:
enum CharacterState {
  /// V7.1 新增: 待机情绪 (由 0/1 分触发)
  // ignore: constant_identifier_names (V7.1 规范要求使用下划线)
  idle_emotion,

  /// V7.1 新增: 待机动动作 (默认回落状态)
  // ignore: constant_identifier_names (V7.1 规范要求使用下划线)
  idle_action,

  /// 开心 (V7.1)
  happy,

  /// 震惊 (V7.1)
  shock,

  /// 散步 (V7.1)
  walk,

  /// 被点击 (V7.1)
  onClick,

  /// 被拖拽 (V7.1)
  onDrag,

  /// 推边界 (V7.1)
  pushBoundary,

  /// 被喂食 (V7.1)
  onFeed,

  /// 离线 (V7.1)
  offline
}
