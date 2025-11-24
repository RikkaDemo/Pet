// (模块 5) V7.1 核心: 角色视图 (交互与移动)
// (V7.2.4 核心重构: 移除了 V7.2.5/V7.2.6 的 "Slab Model" 逻辑)
// (V7.2.4 核心重构: 拖拽桌宠不再移动窗口, 遵从 V7.2.4 规范)

import 'dart:async';
import 'dart:math' show Random, pi, max;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_constants.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_enums.dart';
import 'package:turtle_soup_companion_demo/features/character/character_animator.dart';
import 'package:turtle_soup_companion_demo/state/providers.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

// V7.1 (2.2.2 P5) 自主AI: 切换到 Walk 的随机间隔 (5-15 秒)
const Duration _kMinIdleDuration = Duration(seconds: 5);
const Duration _kMaxIdleDuration = Duration(seconds: 15);
// V7.1 (2.2.2 P5) 自主AI: Walk 状态的随机持续时间 (3-8 秒)
const Duration _kMinWalkDuration = Duration(seconds: 3);
const Duration _kMaxWalkDuration = Duration(seconds: 8);
// V7.1 (2.2.3) 自主AI: Walk 移动速度 (像素/帧)
const double _kWalkSpeed = 1.0;

class CharacterView extends ConsumerStatefulWidget {
  const CharacterView({super.key});

  @override
  ConsumerState<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends ConsumerState<CharacterView>
    with TickerProviderStateMixin {
  // V7.1 (6.2) 核心: 管理桌宠的本地 Offset (在窗口内的偏移)
  // (V7.2.4 保留: V7.2.2 需求 1 - 位置记忆)
  Offset _petLocalOffset = Offset.zero;

  // V7.1 (2.2.2 P5) 自主AI: 计时器
  Timer? _autonomousTimer;
  // V7.1 (2.2.3) 自主AI: Walk 移动
  Ticker? _walkTicker;
  Offset _walkVelocity = Offset.zero;
  final Random _random = Random();

  // V7.2 (2.4.2) 拖拽: 状态
  bool _isDraggingPet = false;

  // V7.2 (2.4.2.A) 屏幕边界
  Rect _screenRect = Rect.zero;

  // V7.2.4 核心: 拖拽时缓存窗口位置 (用于 V7.2.4 需求 6)
  Offset _dragWindowPosCache = Offset.zero;
  Size _dragWindowSizeCache = Size.zero;

  // --- V7.2.4 (需求 6) 状态 ---
  /// V7.2.4 状态: 窗口是否已触达屏幕边缘 (按轴分离)
  bool _isWindowAtLeftEdge = false;
  bool _isWindowAtRightEdge = false;
  bool _isWindowAtTopEdge = false;
  bool _isWindowAtBottomEdge = false;
  // --- V7.2.4 END ---

  @override
  void initState() {
    super.initState();
    // V7.1 (2.2.3) 启动: 初始化 Walk Ticker
    _walkTicker = createTicker(_onWalkTick);

    // V7.1 (2.2.2 P5) 启动: 启动自主AI
    _resetAutonomousTimer(CharacterState.idle_action);

    // V7.2 (2.4.2.A) 启动: 异步获取屏幕信息
    _initScreenInfo();
  }

  /// V7.2 (2.4.2.A)
  Future<void> _initScreenInfo() async {
    // (V7.2.A) 获取屏幕边界
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();

    final position = primaryDisplay.visiblePosition ?? Offset.zero;
    final vSize = primaryDisplay.visibleSize ?? primaryDisplay.size;

    _screenRect =
        Rect.fromLTWH(position.dx, position.dy, vSize.width, vSize.height);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // V7.1 (2.2.3.A) 启动: 将桌宠置于窗口中央
    final winState = ref.read(windowStateProvider);
    final Size windowSize =
        (winState == WindowState.normal) ? kNormalSize : kMinimizedSize;

    // V7.2.1: 使用来自 app_constants.dart 的 kPetWidth/kPetHeight
    _petLocalOffset = Offset(
      (windowSize.width - kPetWidth) / 2,
      (windowSize.height - kPetHeight) / 2,
    );
  }

  @override
  void dispose() {
    _autonomousTimer?.cancel();
    _walkTicker?.dispose();
    super.dispose();
  }

  /// V7.2.4 (需求 6) 辅助: 将窗口矩形限制在屏幕矩形内
  Rect _clampRectToScreen(Rect rect, Rect screen) {
    double left = rect.left;
    double top = rect.top;

    if (rect.left <= screen.left) left = screen.left;
    if (rect.right >= screen.right) left = screen.right - rect.width;
    if (rect.top <= screen.top) top = screen.top;
    if (rect.bottom >= screen.bottom) top = screen.bottom - rect.height;

    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  /// V7.2.4 (需求 6) 辅助: 检查并更新窗口四边是否触达屏幕
  void _updateWindowEdgeFlags(Rect windowRect, Rect screenRect) {
    _isWindowAtLeftEdge = windowRect.left <= screenRect.left;
    _isWindowAtRightEdge = windowRect.right >= screenRect.right;
    _isWindowAtTopEdge = windowRect.top <= screenRect.top;
    _isWindowAtBottomEdge = windowRect.bottom >= screenRect.bottom;
  }

  // --- V7.1 (2.2.2 P5) 自主AI (Idle <-> Walk) ---
  // (V7.2.4 无修改)
  void _resetAutonomousTimer(CharacterState currentState) {
    _autonomousTimer?.cancel();
    if (currentState == CharacterState.idle_action) {
      final durationInSeconds = _kMinIdleDuration.inSeconds +
          _random.nextInt(
              _kMaxIdleDuration.inSeconds - _kMinIdleDuration.inSeconds + 1);
      _autonomousTimer =
          Timer(Duration(seconds: durationInSeconds), _triggerWalk);
    } else if (currentState == CharacterState.walk) {
      final durationInSeconds = _kMinWalkDuration.inSeconds +
          _random.nextInt(
              _kMaxWalkDuration.inSeconds - _kMinWalkDuration.inSeconds + 1);
      _autonomousTimer =
          Timer(Duration(seconds: durationInSeconds), _triggerIdleAction);
    }
  }

  // (V7.2.4 无修改)
  void _triggerWalk() {
    if (!mounted) return;
    final currentState = ref.read(characterStateProvider);
    if (currentState == CharacterState.idle_action && !_isDraggingPet) {
      if (kDebugMode) {
        print("[AI] V7.1 (P5): Idle_Action -> Walk");
      }
      ref.read(characterStateProvider.notifier).setState(CharacterState.walk);
    }
  }

  // (V7.2.4 无修改)
  void _triggerIdleAction() {
    if (!mounted) return;
    final currentState = ref.read(characterStateProvider);
    if (currentState == CharacterState.walk && !_isDraggingPet) {
      if (kDebugMode) {
        print("[AI] V7.1 (P5): Walk -> Idle_Action");
      }
      ref
          .read(characterStateProvider.notifier)
          .setState(CharacterState.idle_action);
    }
  }

  // --- V7.2 (2.2.3) 自主AI (Walk 移动) ---
  // (V7.2.4 无修改)
  void _updateWalkState(CharacterState newState) {
    if (newState == CharacterState.walk) {
      if (!_walkTicker!.isTicking) {
        _walkVelocity =
            Offset.fromDirection(_random.nextDouble() * 2 * pi, _kWalkSpeed);
        _walkTicker!.start();
      }
    } else {
      if (_walkTicker!.isTicking) {
        _walkTicker!.stop();
      }
    }
  }

  // (V7.2.4 无修改)
  void _onWalkTick(Duration elapsed) {
    if (!mounted) return;
    final winState = ref.read(windowStateProvider);
    final Size windowSize =
        (winState == WindowState.normal) ? kNormalSize : kMinimizedSize;
    final Rect windowRect =
        Rect.fromLTWH(0, 0, windowSize.width, windowSize.height);
    Offset newOffset = _petLocalOffset + _walkVelocity;
    Rect petRect = Rect.fromLTWH(
      newOffset.dx,
      newOffset.dy,
      kPetWidth,
      kPetHeight,
    );
    bool collided = false;
    if (petRect.left <= windowRect.left) {
      newOffset = Offset(windowRect.left, newOffset.dy);
      collided = true;
      _walkVelocity = Offset(-_walkVelocity.dx, _walkVelocity.dy);
    } else if (petRect.right >= windowRect.right) {
      newOffset = Offset(windowRect.right - kPetWidth, newOffset.dy);
      collided = true;
      _walkVelocity = Offset(-_walkVelocity.dx, _walkVelocity.dy);
    }
    if (petRect.top <= windowRect.top) {
      newOffset = Offset(newOffset.dx, windowRect.top);
      collided = true;
      _walkVelocity = Offset(_walkVelocity.dx, -_walkVelocity.dy);
    } else if (petRect.bottom >= windowRect.bottom) {
      newOffset = Offset(newOffset.dx, windowRect.bottom - kPetHeight);
      collided = true;
      _walkVelocity = Offset(_walkVelocity.dx, -_walkVelocity.dy);
    }
    if (collided) {
      _walkVelocity = Offset.fromDirection(
        _walkVelocity.direction + (_random.nextDouble() - 0.5) * 0.1,
        _kWalkSpeed,
      );
    }
    setState(() {
      _petLocalOffset = newOffset;
    });
  }

  // --- V7.2 (2.2.3 / 2.4) 交互 (P1-P3) ---
  // (V7.2.4 无修改)
  void _onHover(bool isHovering) {
    if (!mounted) return;
    final platformService = ref.read(platformServiceProvider);
    final notifier = ref.read(characterStateProvider.notifier);
    final currentState = ref.read(characterStateProvider);
    final settings = ref.read(settingsProvider);
    if (isHovering) {
      platformService.setHitTest();
      if (currentState == CharacterState.walk) {
        if (kDebugMode) {
          print("[Interact] V7.1 (2.2.3): Hover stops Walk -> Idle_Action");
        }
        notifier.setState(CharacterState.idle_action);
      }
    } else {
      if (!_isDraggingPet && settings.isClickThroughEnabled) {
        platformService.setClickThrough();
      }
    }
  }

  // (V7.2.4 无修改)
  void _onTap() {
    if (!mounted) return;
    if (ref.read(characterStateProvider) == CharacterState.offline) return;
    if (kDebugMode) {
      print("[Interact] V7.1 (2.4.1): Tap -> OnClick");
    }
    ref.read(characterStateProvider.notifier).setState(CharacterState.onClick);
  }

  /// V7.2.4 (Slab Model) 核心: 拖拽开始 (Pan Start)
  void _onPanStart(DragStartDetails details) async {
    if (!mounted) return;
    if (kDebugMode) {
      print("[Interact] V7.2.4: Drag Start");
    }

    final currentState = ref.read(characterStateProvider);
    final isOffline = currentState == CharacterState.offline;

    // (V7.2.4 需求 1)
    _isDraggingPet = true;

    // (V7.2.4 需求 6) 异步缓存窗口位置
    // 无论何种状态, 都必须缓存窗口位置,
    // 以便在 V7.2.4 中计算 "光标绝对位置" 和 "特殊推边界"
    _dragWindowPosCache = await windowManager.getPosition();

    if (ref.read(windowStateProvider) == WindowState.normal) {
      _dragWindowSizeCache = await windowManager.getSize();

      // --- V7.2.4 (需求 6) START ---
      // 检查窗口是否 *已经* 在屏幕边缘
      final Rect windowRect = Rect.fromLTWH(
        _dragWindowPosCache.dx,
        _dragWindowPosCache.dy,
        _dragWindowSizeCache.width,
        _dragWindowSizeCache.height,
      );
      _updateWindowEdgeFlags(windowRect, _screenRect);
      // --- V7.2.4 (需求 6) END ---
    } else {
      // (V7.2.4) 最小化状态下, 窗口总是在边缘 (逻辑上)
      _isWindowAtLeftEdge = _isWindowAtRightEdge =
          _isWindowAtTopEdge = _isWindowAtBottomEdge = true;
    }

    // (V7.2 修复 B) 确保在 'await' 之后再设置状态
    if (!mounted || !_isDraggingPet) return; // 检查在 await 期间拖拽是否已被取消

    // V7.2.4 (2.4.2.C) Offline 拖拽: 不切换动画
    if (!isOffline) {
      // V7.1 (2.2.2) 触发 OnDrag 状态 (P1)
      ref.read(characterStateProvider.notifier).setState(CharacterState.onDrag);
    }
  }

  /// V7.2.4 (核心重构) 核心: 拖拽中 (Pan Update)
  /// (移除了 V7.2.5/V7.2.6 的 Slab Model 窗口移动逻辑)
  void _onPanUpdate(DragUpdateDetails details) {
    if (!mounted || !_isDraggingPet) return;

    // V7.2.4 (需求 1): 窗口固定, 仅更新桌宠局部坐标
    // (V7.2.4 / V7.2.2 需求 1: 位置记忆)
    _petLocalOffset = _petLocalOffset + details.delta;

    // --- V7.2.4 核心推边界逻辑 ---

    final winState = ref.read(windowStateProvider);
    final Size windowSize =
        (winState == WindowState.normal) ? kNormalSize : kMinimizedSize;
    final Rect windowInnerRect =
        Rect.fromLTWH(0, 0, windowSize.width, windowSize.height);

    // V7.2.1: 使用 kPetWidth/kPetHeight
    final Rect petRect = Rect.fromLTWH(
      _petLocalOffset.dx,
      _petLocalOffset.dy,
      kPetWidth,
      kPetHeight,
    );

    // V7.2.4 (需求 6) 检查: 是否满足"特殊推边界"条件?
    final bool isClickThrough =
        ref.read(settingsProvider).isClickThroughEnabled;
    final bool isWindowAtAnyEdge = _isWindowAtLeftEdge ||
        _isWindowAtRightEdge ||
        _isWindowAtTopEdge ||
        _isWindowAtBottomEdge;

    // "特殊推边界" 仅在 (关闭穿透 且 窗口在屏幕边缘) 时触发
    final bool isSpecialCase = !isClickThrough && isWindowAtAnyEdge;

    // V7.2.4 (需求 4/6) 计算光标在屏幕上的绝对位置
    // (V7.2.5 修正) V7.2.4 规范: 拖拽桌宠时, details.globalPosition 是 *屏幕* 坐标
    // (V7.2.5 修正) Flutter 3.x: details.globalPosition 是 *屏幕* 坐标
    // (V7.2.5 修正) Flutter 2.x: details.globalPosition 是 *窗口* 坐标
    // 假设使用的是现代 Flutter, globalPosition 是屏幕坐标, 不需要 + _dragWindowPosCache
    // final Offset cursorScreenPos = _dragWindowPosCache + details.globalPosition;
    final Offset cursorScreenPos = details.globalPosition; // V7.2.5 修正
    bool triggerPush = false;

    // V7.2.4 (需求 4) 桌宠是否在 *窗口内部* 边缘?
    final bool petAtLeft = petRect.left <= windowInnerRect.left;
    final bool petAtRight = petRect.right >= windowInnerRect.right;
    final bool petAtTop = petRect.top <= windowInnerRect.top;
    final bool petAtBottom = petRect.bottom >= windowInnerRect.bottom;
    final bool isPetAtWindowEdge =
        petAtLeft || petAtRight || petAtTop || petAtBottom;

    if (isSpecialCase) {
      // --- V7.2.4 (需求 6) 逻辑: 特殊推边界 (恢复 V7.2.3 三重检测) ---
      // 1. (窗口在屏幕边缘? - 已满足: _isWindowAt...Edge)
      // 2. (桌宠在窗口边缘? - 已满足: petAt...)
      // 3. (鼠标光标是否 *也* 在屏幕边缘?)
      final bool cursorAtLeft = cursorScreenPos.dx <= _screenRect.left;
      final bool cursorAtRight =
          cursorScreenPos.dx >= (_screenRect.right - 1.0);
      final bool cursorAtTop = cursorScreenPos.dy <= _screenRect.top;
      final bool cursorAtBottom =
          cursorScreenPos.dy >= (_screenRect.bottom - 1.0);

      triggerPush =
          // --- 触发左 ---
          (_isWindowAtLeftEdge && petAtLeft && cursorAtLeft) ||
              // --- 触发右 ---
              (_isWindowAtRightEdge && petAtRight && cursorAtRight) ||
              // --- 触发上 ---
              (_isWindowAtTopEdge && petAtTop && cursorAtTop) ||
              // --- 触发下 ---
              (_isWindowAtBottomEdge && petAtBottom && cursorAtBottom);
    } else {
      // --- V7.2.4 (需求 4) 逻辑: 标准推边界 ---
      // 1. (桌宠在窗口边缘? - isPetAtWindowEdge)
      // 2. (鼠标光标是否在窗口边缘 *或* 窗口之外?)
      final Rect windowScreenRect = Rect.fromLTWH(
        _dragWindowPosCache.dx,
        _dragWindowPosCache.dy,
        windowSize.width,
        windowSize.height,
      );

      // (V7.2.4 需求 4)
      final bool mouseOutsideWindow =
          cursorScreenPos.dx < windowScreenRect.left ||
              cursorScreenPos.dx > windowScreenRect.right ||
              cursorScreenPos.dy < windowScreenRect.top ||
              cursorScreenPos.dy > windowScreenRect.bottom;

      triggerPush = isPetAtWindowEdge && mouseOutsideWindow;
    }

    // --- V7.2.4 状态切换 (需求 5, 10) ---
    final notifier = ref.read(characterStateProvider.notifier);
    final currentState = ref.read(characterStateProvider);
    final isOffline = currentState == CharacterState.offline;

    // V7.2.4 (需求 10) Offline 状态下不触发推边界动画
    if (!isOffline && triggerPush) {
      // (Phase 3) 状态: 正在推边界
      if (currentState != CharacterState.pushBoundary) {
        if (kDebugMode) {
          print("[Interact] V7.2.4 (Phase 3): PushBoundary");
        }
        notifier.setState(CharacterState.pushBoundary);
      }
    } else {
      // (Phase 2) 状态: 自由拖拽
      // V7.2.4 (需求 5): 从 PushBoundary 即时回切
      if (currentState != CharacterState.onDrag) {
        if (kDebugMode) {
          print("[Interact] V7.2.4 (Phase 2): Back to onDrag");
        }
        // V7.2.4 (需求 10) Offline 状态下也不切换到 OnDrag
        if (!isOffline) {
          // V7.2.5 修正: 确保离线时不会切回 OnDrag
          notifier.setState(CharacterState.onDrag);
        }
      }
    }

    // --- V7.2.4 (保留) Clamp 桌宠在窗口内部 ---
    _petLocalOffset = Offset(
      _petLocalOffset.dx.clamp(0.0, windowSize.width - kPetWidth),
      _petLocalOffset.dy.clamp(0.0, windowSize.height - kPetHeight),
    );

    setState(() {
      // _petLocalOffset 已经在上面被修改或 clamp, 此处仅触发重建
    });
  }

  /// V7.2.4 (核心) 核心: 拖拽结束 (Pan End)
  void _onPanEnd(DragEndDetails details) {
    if (!mounted) return;

    if (!_isDraggingPet) return;

    if (kDebugMode) {
      print("[Interact] V7.2.4: Drag End -> Idle_Action");
    }
    _isDraggingPet = false;

    // --- V7.2.4 (需求 6) START ---
    // 检查松开时, 窗口是否在屏幕边缘,
    // 以便下一次拖拽 (onPanStart) 知道初始状态
    if (ref.read(windowStateProvider) == WindowState.normal) {
      // (V7.2.4) 必须异步获取 *最新* 的窗口位置
      // (因为 V7.2.4 需求 2 允许背景拖拽, _dragWindowPosCache 可能已过时)
      // (V7.2.4 修正) 不, _onPanEnd 仅在 _isDraggingPet=true 时触发
      // V7.2.4 规范 1 保证了窗口在拖拽桌宠时 *不* 移动
      // 因此 _dragWindowPosCache *仍然* 是准确的
      final Rect windowRect = Rect.fromLTWH(
        _dragWindowPosCache.dx,
        _dragWindowPosCache.dy,
        _dragWindowSizeCache.width,
        _dragWindowSizeCache.height,
      );
      _updateWindowEdgeFlags(windowRect, _screenRect);
    } else {
      // (V7.2.4) 最小化状态
      _isWindowAtLeftEdge = _isWindowAtRightEdge =
          _isWindowAtTopEdge = _isWindowAtBottomEdge = true;
    }
    // --- V7.2.4 (需求 6) END ---

    // V7.2.4 (需求 8) 规范: 立即切换到 Idle_Action
    _onHover(false); // 恢复穿透 (如果设置开启)
    ref.read(characterStateProvider.notifier).setIdleAction();
  }

  @override
  Widget build(BuildContext context) {
    // V7.1 (2.2.2 P5 / 2.2.3) 核心:
    // 监听 CharacterState 变化
    ref.listen<CharacterState>(characterStateProvider, (prev, next) {
      if (!mounted) return;
      // V7.1 (P5) 启动/停止 自主 AI (Idle <-> Walk 计时器)
      _resetAutonomousTimer(next);
      // V7.1 (2.2.3) 启动/停止 Walk (移动 Ticker)
      _updateWalkState(next);
    });

    // V7.1 (2.7.3) 监听窗口状态, 用于最小化/最大化时重置位置
    ref.listen<WindowState>(windowStateProvider, (prev, next) {
      if (!mounted || prev == next) return;

      final Size windowSize =
          (next == WindowState.normal) ? kNormalSize : kMinimizedSize;

      // V7.2.1: 使用来自 app_constants.dart 的 kPetWidth/kPetHeight
      setState(() {
        _petLocalOffset = Offset(
          (windowSize.width - kPetWidth) / 2, // <-- V7.2.1
          (windowSize.height - kPetHeight) / 2, // <-- V7.2.1
        );
      });

      // V7.2.4 (需求 6): 窗口状态改变时, 重置边界标志
      if (next == WindowState.minimized) {
        _isWindowAtLeftEdge = _isWindowAtRightEdge =
            _isWindowAtTopEdge = _isWindowAtBottomEdge = true;
      } else {
        // (V7.2.4) 当最大化时, 我们 *不知道* 窗口是否在边缘
        // (V7.2.4) V7.1 (2.7.3) "调用 window_manager.center()"
        // (V7.2.4) 因此, 它们 *不* 在边缘
        _isWindowAtLeftEdge = _isWindowAtRightEdge =
            _isWindowAtTopEdge = _isWindowAtBottomEdge = false;
      }
    });

    // --- V7.2 (2.4.2.D) 小尺寸交互修复 ---
    // (V7.2.4 保留)
    const minInteractiveSize = 48.0;
    final effectiveWidth = max(kPetWidth, minInteractiveSize);
    final effectiveHeight = max(kPetHeight, minInteractiveSize);
    // --- V7.2 (2.4.2.D) END ---

    // V7.1 (6.2) 核心: 渲染
    return Positioned(
      // V7.1 (6.2) 核心: 应用本地 Offset
      left: _petLocalOffset.dx,
      top: _petLocalOffset.dy,
      width: effectiveWidth,
      height: effectiveHeight,

      // V7.1 (2.1 / 2.4 / 2.2.3) 交互层
      child: MouseRegion(
        onEnter: (PointerEnterEvent event) => _onHover(true),
        onExit: (PointerExitEvent event) => _onHover(false),

        // V7.1 (2.4) 交互 (点击/拖拽)
        child: GestureDetector(
          // V7.1 (2.4.1) 单击
          onTap: _onTap,
          // V7.2.4 (核心) 拖拽
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,

          // V7.1 (模块 5) 动画层
          child: const Center(
            child: SizedBox(
              // V7.2.1: 使用来自 app_constants.dart 的 kPetWidth/kPetHeight
              width: kPetWidth,
              height: kPetHeight,
              child: CharacterAnimator(),
            ),
          ),
        ),
      ),
    );
  }
}
