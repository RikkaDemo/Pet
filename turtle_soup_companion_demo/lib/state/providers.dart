// (V6.0 核心) 汇集所有模块的 Providers 和 Services
// 供 UI 层 和 Service 层 互相调用

// --- 模块 1 & 2 (Services) ---
export 'package:turtle_soup_companion_demo/core/services/window_service.dart';
export 'package:turtle_soup_companion_demo/core/services/platform_service.dart';

// --- 模块 3 (State) ---
export 'package:turtle_soup_companion_demo/state/window_state.dart';
export 'package:turtle_soup_companion_demo/state/settings_state.dart';
export 'package:turtle_soup_companion_demo/state/character_state.dart';
export 'package:turtle_soup_companion_demo/state/game_data_state.dart';

// --- 模块 4 (Service) ---
export 'package:turtle_soup_companion_demo/core/services/websocket_service.dart';

// --- 模块 3/4 辅助 (Models) ---
export 'package:turtle_soup_companion_demo/core/models/websocket_message.dart';
