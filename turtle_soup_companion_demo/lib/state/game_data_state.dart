// (模块 3) V6.0 (2.3): UI 面板数据
// 职责: 存储所有由 WebSocket 推送的、用于UI显示的数据

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/core/models/websocket_message.dart';

/// (模块 3) V6.0 (2.3.2): 左上角积分面板数据
final playerScoreListProvider = StateProvider<List<PlayerScore>>(
  (ref) => [],
);

/// (模块 3) V6.0 (2.3.3): 右下角信息汇总面板数据
final summaryContentProvider = StateProvider<String>(
  (ref) => "正在连接服务器...", // 初始文本
);

/// (模块 3) V6.0 (2.3.1): 头顶对话框数据
/// (V6.0: 存储 '是'/'否'/'无关' 字符串)
final latestAnswerProvider = StateProvider<String?>(
  (ref) => null, // 初始为 null, 不显示
);
