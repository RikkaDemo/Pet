#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // V5.0 (Module 1) Fix: Re-enable window creation but start minimized
  // window_manager plugin needs a window to exist, but we can hide it initially
  Win32Window::Point origin(0, 0);
  Win32Window::Size size(1, 1); // Minimal size, will be overridden by Dart code
  
  // Create window but hide it, Dart side window_manager will reset size and position
  if (!window.Create(L"turtle_soup_companion_demo", origin, size)) {
    return EXIT_FAILURE;
  }
  
  // Initially hide window, wait for Dart code to control display
  window.SetQuitOnClose(true);
  ::ShowWindow(window.GetHandle(), SW_HIDE); // Initially hidden

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
