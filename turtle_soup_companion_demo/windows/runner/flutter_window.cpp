#include "flutter_window.h"

#include <optional>

// V7.1 (Fix 2 & 4) 
// 
// 
#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib")

#include "flutter/generated_plugin_registrant.h"

// V5.0 (Module 2) Added:
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
// #include <flutter/json_method_codec.h> // V5.0 (Module 2) REMOVED: This header caused C1083 error and was not needed.
#include <windows.h> // For SetWindowLong

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  // --- V7.1 (Fix 4) START: (V7.2.1 保留: 这是实现透明窗口所必需的)
  // 
  // 
  MARGINS margins = { -1 }; 
  ::DwmExtendFrameIntoClientArea(GetHandle(), &margins);
  RECT rect;
  ::GetWindowRect(GetHandle(), &rect);
  ::SetWindowPos(GetHandle(), nullptr, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, 
      SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
  // --- V7.1 (Fix 4) END ---

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // V5.0 (Module 2) Added: Register Platform Channel (1/2)
  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(),
      "com.example.turtle_soup_companion/platform_service", // Must match Dart name
      &flutter::StandardMethodCodec::GetInstance()
  );

  // V5.0 (Module 2) Added: Set Channel Handler (2/2)
  // (V7.2.1 保留: 穿透逻辑是正确的)
  channel.SetMethodCallHandler(
      [handle = GetHandle()](const auto& call, auto result) {
        if (call.method_name().compare("setClickThrough") == 0) {
          // V5.0 Core: Enable click-through (WS_EX_TRANSPARENT)
          SetWindowLong(handle, GWL_EXSTYLE,
                        GetWindowLong(handle, GWL_EXSTYLE) | WS_EX_TRANSPARENT);
          result->Success();
        } else if (call.method_name().compare("setHitTest") == 0) {
          // V5.0 Core: Disable click-through (remove WS_EX_TRANSPARENT)
          SetWindowLong(handle, GWL_EXSTYLE,
                        GetWindowLong(handle, GWL_EXSTYLE) & ~WS_EX_TRANSPARENT);
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
  // V5.0 (Module 2) End of additions

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // V5.0 Fix: 移除自动显示逻辑，让 Dart 代码控制窗口显示
  // flutter_controller_->engine()->SetNextFrameCallback([&]() {
  //   this->Show();
  // });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;

    // --- V7.1 (Fix 2) START: (V7.2.1 移除)
    // 
    // 
    // (V7.2.1 移除: 此 hack 会使 Flutter 的 GestureDetector 和 MouseRegion 失效)
    // case WM_NCHITTEST: {
    //   LRESULT hit = Win32Window::MessageHandler(hwnd, message, wparam, lparam);
    //   if (hit == HTCLIENT) {
    //     return HTCAPTION; 
    //   }
    //   return hit;
    // }
    // --- V7.1 (Fix 2) END ---

    // --- V7.1 (Fix 4) START: (V7.2.1 保留: 这是实现无边框所必需的)
    // 
    // 
    case WM_NCCALCSIZE:
      if (wparam == TRUE) {
        // 
        // 
        // 
        return 0;
      }
      break; 
    // --- V7.1 (Fix 4) END ---
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
