// [文件6]
import 'dart:ui';

/// V5.0 (2.1): 普通状态尺寸
const Size kNormalSize = Size(735, 600);
//透明缺失问题:原先尺寸是800*600，但是由于宽度缺失了大概65像素（右边界）所以宽度得比原来小
/// V5.0 (2.1): 最小化状态尺寸
const Size kMinimizedSize = Size(300, 300);

// --- (V7.2.1 规范 2.2.1 新增) ---
/// V7.2.1 (2.2.1): 桌宠基础尺寸常量
const double kPetWidth = 350.0;

/// V7.2.1 (2.2.1): 桌宠基础尺寸常量
const double kPetHeight = 400.0;
// --- (V7.2.1 规范 2.2.1 新增) END ---

// --- (V5.0 模块 4 新增) ---

/// V5.0 (3.1): WebSocket 连接地址
const String kWebSocketUrl = 'ws://localhost:8080/ws/game';

/// V5.0 (3.1): 心跳检测间隔 (秒)
const Duration kHeartbeatInterval = Duration(seconds: 30);

/// V5.0 (3.3): WebSocket 断线重连尝试间隔 (秒)
const Duration kReconnectDelay = Duration(seconds: 5);
