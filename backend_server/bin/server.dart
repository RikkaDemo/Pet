// bin/server.dart  或  server.dart
import 'dart:io';
import 'dart:convert';

// [AI 集成] 我们的 bridge.py 将连接到 /ws/bridge
final String GAME_PATH = '/ws/game';
final String BRIDGE_PATH = '/ws/bridge';

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('WebSocket server listening on ws://localhost:$port');
  print('  - 游戏客户端 (main.dart) 请连接: ws://localhost:$port$GAME_PATH');
  print('  - AI 网桥 (bridge.py)   请连接: ws://localhost:$port$BRIDGE_PATH');

  final wsServer = _SoupServer();
  await for (HttpRequest req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      // [AI 集成] 根据 URL 路径路由到不同的处理器
      if (req.uri.path == GAME_PATH) {
        final socket = await WebSocketTransformer.upgrade(req);
        wsServer.handleClient(socket);
      } else if (req.uri.path == BRIDGE_PATH) {
        final socket = await WebSocketTransformer.upgrade(req);
        wsServer.handleBridge(socket); // <--- AI 网桥的新处理器
      } else {
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Unknown WebSocket path')
          ..close();
      }
    } else {
      req.response
        ..statusCode = HttpStatus.forbidden
        ..write('WebSocket only')
        ..close();
    }
  }
}

class _SoupServer {
  // 连接映射
  final Map<WebSocket, int> _connToId = {};
  final Map<int, WebSocket> _idToConn = {};

  // [AI 集成] 为 bridge.py 单独保存一个连接
  WebSocket? _bridgeChannel;

  // —— 全局状态 —— //
  int _nextId = 1; // 1 号为主持人（首个连接）
  bool running = false;
  // ... (您原有的其他状态变量) ...
  bool waitingOpening = false;
  bool hostOpeningUsed = false;
  int? speakingId;
  int round = 1;
  List<int> order = []; // 含主持人 1
  bool awaitingVerdict = false; // 是否等待主持人判定（高亮）

  // —— 计分 —— //
  final Map<int, int> scores = {}; // 玩家积分（id -> total）

  // —— 头像（跨端同步，base64 PNG/JPG）—— //
  final Map<int, String> avatarsB64 = {}; // id -> base64（不含 dataURI 头）

  // —— 历史（最近 200 条，可调）—— //
  final int _maxHistory = 200;
  final List<Map<String, dynamic>> _histOrdered =
      []; // system/opening/chat/verdict/score/avatar
  final List<Map<String, dynamic>> _histFree = []; // freechat

  // ===== 工具：把 int 键的 Map 转成 string 键（供 jsonEncode 使用） =====
  Map<String, T> _stringKeys<T>(Map<int, T> m) {
    final out = <String, T>{};
    m.forEach((k, v) => out['$k'] = v);
    return out;
  }

  // [AI 集成] 1. 新增: AI 网桥的连接处理器
  void handleBridge(WebSocket ws) {
    print('[Server] ✅ AI Bridge (bridge.py) connected!');
    _bridgeChannel = ws;

    // 监听来自 bridge 的 AI 结果
    ws.listen(
      _handleBridgeMessage, // <--- 专门的 AI 结果处理器
      onDone: () {
        print('[Server] ❌ AI Bridge disconnected.');
        _bridgeChannel = null;
      },
      onError: (e) {
        print('[Server] ❌ AI Bridge error: $e');
        _bridgeChannel = null;
      },
    );
  }

  // [AI 集成] 2. 新增: AI 结果的处理器
  void _handleBridgeMessage(dynamic message) {
    print('[Server] ⬅️ Received AI Result from bridge: $message');
    try {
      final data = json.decode(message);
      final type = data['type'];

      // 我们只关心 AI 裁决的结果
      if (type == 'ai_judge_question_result') {
        // 检查 AI 是否返回了错误
        if (data['error'] != null) {
          print('[Server] ⚠️ AI returned an error: ${data['error']}');
          // (可选) 如果 AI 失败，我们可以让主持人手动裁决
          // （目前什么也不做，awaitingVerdict 保持 true 即可）
          return;
        }

        final judgeAnswer = data['judge_answer']?.toString() ?? '...';
        // final scoreResult = data['score_result']; // (可选) 您也可以处理分数

        // [核心] 得到 AI 答案后，我们调用现有的 _onVerdict 逻辑
        // 就像主持人亲手点击了按钮一样
        // 游戏会自动推进到下一个玩家
        if (awaitingVerdict && speakingId != null) {
          print('[Server] 🤖 AI is submitting verdict: "$judgeAnswer"');
          _onVerdict(judgeAnswer);
        } else {
          print('[Server] ⚠️ AI sent a verdict, but we were not awaiting one.');
        }
      }
    } catch (e) {
      print('[Server] Error parsing bridge message: $e');
    }
  }

  // 入口：处理新连接 (这是您原有的函数)
  void handleClient(WebSocket ws) {
    final id = _assignId(ws);
    final isHost = (id == 1);

    // welcome
    _send(ws, {
      'type': 'welcome',
      'playerId': id,
      'isHost': isHost,
    });

    // 首次下发历史 & 积分 & 头像（注意把 Map<int,...> 的键转成字符串）
    _send(ws, {
      'type': 'bulkSync',
      'ordered': _histOrdered,
      'free': _histFree,
      'scores': _stringKeys(scores),
      'avatars': _stringKeys(avatarsB64),
    });

    // 下发当前状态
    _broadcastState();

    ws.listen((data) {
      try {
        final msg = jsonDecode(data);
        final type = msg['type'];

        switch (type) {
          case 'restore':
            _send(ws, {
              'type': 'welcome',
              'playerId': id,
              'isHost': isHost,
            });
            _send(ws, {
              'type': 'bulkSync',
              'ordered': _histOrdered,
              'free': _histFree,
              'scores': _stringKeys(scores),
              'avatars': _stringKeys(avatarsB64),
            });
            _broadcastState();
            break;

          case 'hostControl':
            if (!isHost) break;
            final action = (msg['action'] ?? '').toString();
            switch (action) {
              case 'start':
                _onStart();
                break;
              case 'stop':
                _onStop();
                break;
              case 'opening':
                _onOpening((msg['text'] ?? '').toString());
                break;
              case 'skipOpening':
                _onSkipOpening();
                break;
              case 'verdict':
                // [AI 集成] 主持人仍然可以手动裁决
                print('[Server] 👨‍⚖️ Host is submitting verdict manually.');
                _onVerdict((msg['verdict'] ?? '').toString());
                break;
              case 'score':
                final to = msg['to'];
                final delta = msg['delta'];
                if (to is int && delta is int && delta >= 0 && delta <= 3) {
                  _applyScore(to, delta);
                }
                break;
            }
            break;

          case 'avatar':
            // ... (您原有的 'avatar' 逻辑，完全不变) ...
            final pngB64 = (msg['pngB64'] ?? '').toString();
            if (pngB64.isEmpty) break;
            if (pngB64.length > 140000) {
              print('Avatar too large from id=$id, ignored.');
              break;
            }
            avatarsB64[id] = pngB64;
            final objAvatar = {
              'type': 'avatar',
              'id': id,
              'pngB64': pngB64,
              'ts': DateTime.now().toIso8601String(),
            };
            _broadcast(objAvatar);
            _pushOrdered(objAvatar); // 作为事件记录（可选）
            _broadcastState(); // state 中也包含 avatars
            break;

          case 'chat':
            // 顺序发言：仅当前发言观众可说
            if (!running || waitingOpening) break;
            if (speakingId != id) break;

            final text = (msg['text'] ?? '').toString();
            if (text.isEmpty) break;

            final objChat = {
              'type': 'chat',
              'from': id,
              'text': text,
              'ts': DateTime.now().toIso8601String(),
            };
            _broadcast(objChat);
            _pushOrdered(objChat);

            // [AI 集成] 3. 修改: 玩家提问时，将任务发送给 AI
            _sendTaskToAI(objChat);

            awaitingVerdict = true;
            _broadcastState();
            break;

          case 'freechat':
            // ... (您原有的 'freechat' 逻辑，完全不变) ...
            if (id == 1) break;
            final text2 = (msg['text'] ?? '').toString();
            if (text2.isEmpty) break;

            final objFree = {
              'type': 'freechat',
              'from': id,
              'text': text2,
              'ts': DateTime.now().toIso8601String(),
            };
            _broadcast(objFree);
            _pushFree(objFree);
            break;
        }
      } catch (e) {
        print('Error handling message: $e');
      }
    }, onDone: () {
      _onDisconnect(ws);
    }, onError: (e) {
      print('WS error: $e');
      _onDisconnect(ws);
    });
  }

  // [AI 集成] 4. 新增: 打包并发送任务到 AI Bridge
  void _sendTaskToAI(Map<String, dynamic> chatObject) {
    if (_bridgeChannel == null) {
      print(
          '[Server] ⚠️ Bridge not connected. AI cannot judge. Host must judge manually.');
      return; // AI 离线，主持人必须手动裁决
    }

    // 1. 找到故事原文 (story_truth)，我们假设它是 'opening' 类型的消息
    final openingMsg = _histOrdered.firstWhere(
      (h) => h['type'] == 'opening',
      orElse: () => {'text': ''}, // 如果找不到，默认为空
    );
    final storyTruth = openingMsg['text'] as String;
    if (storyTruth.isEmpty) {
      print(
          '[Server] ⚠️ Cannot find "story_truth" (opening). AI may be inaccurate.');
    }

    // 2. 构造 AI 需要的历史记录 (bridge.py V10 需要这个格式)
    // 格式: [{"role": "user", "content": "..."}]
    final List<Map<String, String>> aiHistory = [];
    for (final h in _histOrdered) {
      if (h['type'] == 'chat') {
        aiHistory.add({"role": "user", "content": h['text']});
      } else if (h['type'] == 'verdict') {
        aiHistory.add({"role": "assistant", "content": h['verdict']});
      }
    }

    // 3. 打包任务
    final aiTask = {
      "type": "ai_judge_question", // AI Bridge 认识的类型
      "request_id": chatObject['ts'], // 使用聊天的时间戳作为唯一 ID
      "story_truth": storyTruth,
      "history": aiHistory, // 发送格式化后的历史
      "new_question": chatObject['text'],
    };

    // 4. 发送
    print('[Server] ➡️ Forwarding task to Bridge...');

    // --------------------------------------------------
    // [!! BUG 修复 !!]
    // 之前错误地写了 .sink.add (那是 WebSocketChannel 的用法)
    // dart:io:WebSocket (来自 HttpServer) 直接使用 .add
    _bridgeChannel!.add(jsonEncode(aiTask)); // <--- 已修复
    // --------------------------------------------------
  }

  // 分配玩家 ID（首个为主持人 1）
  // ... (您原有的 `_assignId` 逻辑，完全不变) ...
  int _assignId(WebSocket ws) {
    if (!_idToConn.containsKey(1)) {
      _connToId[ws] = 1;
      _idToConn[1] = ws;
      if (!order.contains(1)) order.insert(0, 1);
      scores.putIfAbsent(1, () => 0);
      print('New host connected: id=1');
      return 1;
    }
    while (_idToConn.containsKey(_nextId) || _nextId == 1) {
      _nextId++;
    }
    final id = _nextId++;
    _connToId[ws] = id;
    _idToConn[id] = ws;
    if (!order.contains(id)) order.add(id);
    scores.putIfAbsent(id, () => 0);
    print('New user connected: id=$id');
    return id;
  }

  // ... (您原有的 `_onDisconnect` 逻辑，完全不变) ...
  void _onDisconnect(WebSocket ws) {
    final id = _connToId.remove(ws);
    if (id != null) {
      _idToConn.remove(id);
      order.remove(id);
      if (speakingId == id) {
        _advanceSpeaker();
      }
      print('User disconnected: id=$id');
    }
    _broadcastState();
  }

  // —— 流程控制 —— //
  // ... (您原有的 `_onStart`, `_onStop`, `_onOpening`, `_onSkipOpening` 逻辑，完全不变) ...
  void _onStart() {
    running = true;
    waitingOpening = true;
    hostOpeningUsed = false;
    speakingId = null;
    round = 1;
    awaitingVerdict = false;

    final obj = {
      'type': 'system',
      'text': '游戏开始，等待主持人开场',
      'ts': DateTime.now().toIso8601String(),
    };
    _broadcast(obj);
    _pushOrdered(obj);
    _broadcastState();
  }

  void _onStop() {
    running = false;
    waitingOpening = false;
    awaitingVerdict = false;

    final obj = {
      'type': 'system',
      'text': '游戏已停止',
      'ts': DateTime.now().toIso8601String(),
    };
    _broadcast(obj);
    _pushOrdered(obj);
    _broadcastState();
  }

  void _onOpening(String text) {
    if (!running || !waitingOpening || hostOpeningUsed) return;
    hostOpeningUsed = true;
    waitingOpening = false;

    final obj = {
      'type': 'opening',
      'text': text,
      'ts': DateTime.now().toIso8601String(),
    };
    _broadcast(obj);
    _pushOrdered(obj);

    _setFirstAudienceAsSpeaker();
    _broadcastState();
  }

  void _onSkipOpening() {
    if (!running || !waitingOpening) return;
    hostOpeningUsed = true;
    waitingOpening = false;

    final obj = {
      'type': 'system',
      'text': '主持人跳过开场',
      'ts': DateTime.now().toIso8601String(),
    };
    _broadcast(obj);
    _pushOrdered(obj);

    _setFirstAudienceAsSpeaker();
    _broadcastState();
  }

  // ... (您原有的 `_onVerdict` 逻辑，完全不变) ...
  // [AI 集成] AI 和主持人最终都会调用这个函数
  void _onVerdict(String verdict) {
    if (!running) return;
    if (speakingId == null) return;

    final obj = {
      'type': 'verdict',
      'to': speakingId,
      'verdict': verdict,
      'ts': DateTime.now().toIso8601String(),
    };
    _broadcast(obj);
    _pushOrdered(obj);

    awaitingVerdict = false;
    _advanceSpeaker();
    _broadcastState();
  }

  // ... (您原有的 `_setFirstAudienceAsSpeaker` 和 `_advanceSpeaker` 逻辑，完全不变) ...
  void _setFirstAudienceAsSpeaker() {
    final audience = order.where((id) => id != 1).toList();
    if (audience.isEmpty) {
      speakingId = null;
      return;
    }
    speakingId = audience.first;
  }

  void _advanceSpeaker() {
    final audience = order.where((id) => id != 1).toList();
    if (audience.isEmpty) {
      speakingId = null;
      return;
    }
    if (speakingId == null) {
      speakingId = audience.first;
      return;
    }
    final idx = audience.indexOf(speakingId!);
    if (idx < 0 || idx == audience.length - 1) {
      round += 1;
      speakingId = audience.first;
    } else {
      speakingId = audience[idx + 1];
    }
  }

  // —— 计分逻辑 —— //
  // ... (您原有的 `_applyScore` 逻辑，完全不变) ...
  void _applyScore(int to, int delta) {
    scores[to] = (scores[to] ?? 0) + delta;

    final obj = {
      'type': 'score',
      'to': to,
      'delta': delta,
      'total': scores[to],
      'ts': DateTime.now().toIso8601String(),
    };
    _broadcast(obj);
    _pushOrdered(obj);
    _broadcastState();
  }

  // —— 历史入库 —— //
  // ... (您原有的 `_pushOrdered` 和 `_pushFree` 逻辑，完全不变) ...
  void _pushOrdered(Map<String, dynamic> obj) {
    _histOrdered.add(obj);
    if (_histOrdered.length > _maxHistory) {
      _histOrdered.removeAt(0);
    }
  }

  void _pushFree(Map<String, dynamic> obj) {
    _histFree.add(obj);
    if (_histFree.length > _maxHistory) {
      _histFree.removeAt(0);
    }
  }

  // —— 广播/发送 —— //
  // ... (您原有的 `_broadcastState`, `_broadcast`, `_send` 逻辑，完全不变) ...
  void _broadcastState() {
    final payload = {
      'type': 'state',
      'running': running,
      'waitingOpening': waitingOpening,
      'hostOpeningUsed': hostOpeningUsed,
      'speakingId': speakingId,
      'round': round,
      'order': order,
      'awaitingVerdict': awaitingVerdict,
      'scores': _stringKeys(scores), // ★ 键转字符串
      'avatars': _stringKeys(avatarsB64) // ★ 键转字符串
    };
    print('[STATE] running=$running waitingOpening=$waitingOpening '
        'speakingId=$speakingId round=$round '
        'awaitingVerdict=$awaitingVerdict online=${_idToConn.length} '
        'scores=${scores.length} avatars=${avatarsB64.length}');
    _broadcast(payload);
  }

  void _broadcast(Map<String, dynamic> obj) {
    final text = jsonEncode(obj);
    for (final ws in _connToId.keys.toList()) {
      try {
        ws.add(text);
      } catch (_) {}
    }
  }

  void _send(WebSocket ws, Map<String, dynamic> obj) {
    ws.add(jsonEncode(obj));
  }
}
