// websocket_service
// (模块 4) V7.0 (3.2): WebSocket 服务
// 职责: 自动(重)连接, V7.0 心跳, V7.0 消息解析, 并调用 模块 3 的 providers

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/models/websocket_message.dart';
import 'package:turtle_soup_companion_demo/core/utils/app_constants.dart';
// V7.0 (模块 4) 依赖: 角色状态, 游戏数据
import 'package:turtle_soup_companion_demo/state/character_state.dart';
import 'package:turtle_soup_companion_demo/state/game_data_state.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// (模块 4) 注册为 Riverpod Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});

class WebSocketService {
  final Ref _ref;
  WebSocketService(this._ref);

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer; // V7.0 (3.1) 新增: 心跳计时器
  bool _isConnected = false;

  /// (模块 4) 核心: 启动并自动重连
  void connect() {
    // 防止重复连接
    if (_isConnected ||
        (_reconnectTimer != null && _reconnectTimer!.isActive)) {
      return;
    }

    if (kDebugMode) {
      print("[WebSocket] 正在连接到 $kWebSocketUrl ...");
    }

    // V7.0 (3.3): 首次连接时, 更新UI为"正在连接"
    _ref.read(summaryContentProvider.notifier).state = "正在连接服务器...";

    try {
      // 1. 尝试连接
      _channel = IOWebSocketChannel.connect(kWebSocketUrl);
      _channel!.stream.listen(
        // 2. (成功) 收到消息
        _onMessageReceived,
        // 3. (失败) 发生错误
        onError: _onError,
        // 4. (断开) 连接关闭
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (e) {
      // 捕获同步连接错误 (例如: 格式错误的 URL)
      _onError(e);
    }
  }

  /// (模块 4) 核心: 收到消息
  void _onMessageReceived(dynamic message) {
    if (!_isConnected) {
      _isConnected = true;
      if (kDebugMode) {
        print("[WebSocket] 连接成功! 已收到第一条消息。");
      }
      // V7.0 (3.3): 模块 4 通知 模块 3 (重连成功)
      _ref.read(characterStateProvider.notifier).setOnline();
      // V7.0 (3.1) 核心: 连接成功后, 启动心跳
      _startHeartbeat();
      // V7.0 (3.3): 更新UI
      _ref.read(summaryContentProvider.notifier).state = "已连接。";
    }

    if (kDebugMode) {
      print("[WebSocket] 收到消息: $message");
    }

    // V7.0 (3.2.2): 解析消息
    _parseMessage(message);
  }

  /// (模块 4) 核心: 消息解析与分发 (V7.0 逻辑重构)
  void _parseMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String type = data['type'] as String? ?? 'unknown';

      // V7.0 (模块 4) 规范:
      // 根据 type 将任务分发给 模块 3 的 Notifiers
      final characterNotifier = _ref.read(characterStateProvider.notifier);

      switch (type) {
        // V7.0 类型 1: 法官回答
        case 'judge_answer':
          final answer = JudgeAnswer.fromJson(data);
          // V7.0 (2.6.2): 驱动状态
          characterNotifier.setScoreBasedState(answer.score);
          // V7.0 (模块 4): 更新UI (2.3.1)
          _ref.read(latestAnswerProvider.notifier).state = answer.answer;
          break;

        // V7.0 类型 2: 积分更新
        case 'score_update':
          final scoreUpdate = ScoreUpdate.fromJson(data);
          // V7.0 (模块 4) 核心: 只更新数据, 不驱动状态
          _ref.read(playerScoreListProvider.notifier).state =
              scoreUpdate.players;
          break;

        // V7.0 类型 3: 信息汇总
        case 'summary_update':
          final summary = SummaryUpdate.fromJson(data);
          // V7.0 (模块 4) 核心: 更新数据 (2.3.3)
          _ref.read(summaryContentProvider.notifier).state = summary.content;
          break;

        // V7.0 类型 5: 游戏胜利 (强制 Shock)
        case 'game_solved':
          characterNotifier.triggerGameSolved();
          break;

        // V7.0 类型 4: 心跳响应
        case 'pong':
          // (V7.0 (3.1) 收到 pong, 重置超时 (如果需要))
          if (kDebugMode) {
            print("[WebSocket] 收到 Pong 心跳响应。");
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print("[WebSocket] 消息解析失败: $e");
      }
    }
  }

  /// (模块 4) 核心: 发生错误
  void _onError(dynamic error) {
    if (kDebugMode) {
      print("[WebSocket] 发生错误: $error");
    }
    // (V7.0 备注: SocketException (拒绝连接) 是最常见的 'error')
    _onDone(); // 错误也视为连接断开
  }

  /// (模块 4) 核心: 连接断开
  void _onDone() {
    if (kDebugMode) {
      print("[WebSocket] 连接已断开。");
    }

    if (_isConnected) {
      // V7.0 (3.3): 模块 4 通知 模块 3 (掉线)
      _ref.read(characterStateProvider.notifier).setOffline();
      // V7.0 (3.3): 更新UI
      _ref.read(summaryContentProvider.notifier).state = "已断开连接, 正在重连...";
    }

    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
    _stopHeartbeat(); // V7.0 (3.1) 核心: 断开时停止心跳

    // V7.0 (3.3): 自动重连逻辑
    // 确保只有一个重连计时器在运行
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      if (kDebugMode) {
        // V7.0 (3.3) 修正: 使用 kReconnectDelay
        print("[WebSocket] ${kReconnectDelay.inSeconds}秒后尝试重连...");
      }
      _reconnectTimer = Timer(kReconnectDelay, () {
        // V7.0 (3.3) 修正
        connect(); // 重新触发连接流程
      });
    }
  }

  /// V7.0 (3.1) 核心: 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel(); // 先取消旧的
    _heartbeatTimer = Timer.periodic(kHeartbeatInterval, (timer) {
      if (_isConnected) {
        // V7.0 (3.2.1): 发送 ping
        sendMessage('{"type": "ping"}');
      }
    });
  }

  /// V7.0 (3.1) 核心: 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// (模块 4) V7.0 (3.2.1): 主动发送消息 (用于心跳和未来的 "请求汇总")
  void sendMessage(String message) {
    if (_isConnected && _channel != null) {
      if (kDebugMode) {
        print("[WebSocket] 发送消息: $message");
      }
      _channel!.sink.add(message);
    } else {
      if (kDebugMode) {
        print("[WebSocket] 无法发送消息: 未连接。");
      }
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _stopHeartbeat(); // V7.0 (3.1)
    _channel?.sink.close();
    _isConnected = false;
    if (kDebugMode) {
      print("[WebSocket] 服务已释放。");
    }
  }
}
