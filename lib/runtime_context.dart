import 'runtime_context_stub.dart'
    if (dart.library.io) 'runtime_context_io.dart'
    if (dart.library.html) 'runtime_context_web.dart'
    as runtime_impl;

enum RuntimeMode { desktopBrowser, mobileBrowser, androidApp, iosApp, other }

enum MotionSupport { none, browserAccelerometer, deviceAccelerometer }

class RuntimeContext {
  const RuntimeContext({
    required this.mode,
    required this.motionSupport,
    required this.needsBrowserAccelerometerPrompt,
  });

  final RuntimeMode mode;
  final MotionSupport motionSupport;
  final bool needsBrowserAccelerometerPrompt;
}

RuntimeContext detectRuntimeContext() {
  return runtime_impl.detectRuntimeContext();
}

Future<bool> requestBrowserAccelerometerAccess() {
  return runtime_impl.requestBrowserAccelerometerAccess();
}
