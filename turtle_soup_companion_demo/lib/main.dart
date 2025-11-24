import 'package:flutter/material.dart'; // <--- V7.1 修正: 必须导入 Material
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtle_soup_companion_demo/app_view.dart';

// (V6.0 核心) 导入所有 providers
import 'package:turtle_soup_companion_demo/state/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // (V6.0 核心修改)
  // ----------------------------------------------------
  // 1. (模块3) 手动创建一个 Provider 容器
  final container = ProviderContainer();

  // 2. (模块1) V6.0 (2.7.5): 使用容器初始化窗口服务 (居中启动)
  await container.read(windowServiceProvider).init();

  // 3. (模块2) V6.0 (2.7.4): 使用容器初始化平台服务 (设置初始穿透)
  await container.read(platformServiceProvider).init();

  // 4. (模块4) V6.0 (3.1):
  //    使用容器来获取 WebSocketService 并立即调用 connect()
  //    以启动网络连接和心跳。
  container.read(webSocketServiceProvider).connect();
  // ----------------------------------------------------

  runApp(
    // 5. (模块3) 使用 UncontrolledProviderScope 将我们创建的容器
    //    传递给 Flutter 应用。
    UncontrolledProviderScope(
      container: container,

      // V7.1 修正:
      // 必须使用 MaterialApp 作为 App 根, 否则 Scaffold 会崩溃。
      // 必须将 MaterialApp 设为透明, 否则窗口会显示为 '白板'。
      child: MaterialApp(
        // V7.1 (2.1) 规范: 移除 DEBUG 横幅
        debugShowCheckedModeBanner: false,

        // V7.1 (2.1) 规范: 修复 "白板" 问题
        theme: ThemeData(
            // 确保 MaterialApp 的画布背景是透明的
            // canvasColor: Colors.transparent,
            // canvasColor: const Color.fromARGB(0, 11, 11, 11),
            // (V7.1 备注: AppView 里的 Scaffold 也有 backgroundColor: Colors.transparent,
            //  但 theme 里的这个设置是必须的, 用于确保窗口的根是透明的)
            // scaffoldBackgroundColor: Colors.transparent,
            // scaffoldBackgroundColor: const Color.fromARGB(0, 11, 11, 11),
            ),

        home: const AppView(),
      ),
    ),
  );
}
