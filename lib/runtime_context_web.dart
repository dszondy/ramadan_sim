import 'package:flutter/foundation.dart';

import 'runtime_context.dart';

RuntimeContext detectRuntimeContext() {
  final isMobileBrowser =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  return RuntimeContext(
    mode: isMobileBrowser
        ? RuntimeMode.mobileBrowser
        : RuntimeMode.desktopBrowser,
    motionSupport: isMobileBrowser
        ? MotionSupport.browserAccelerometer
        : MotionSupport.none,
    needsBrowserAccelerometerPrompt: isMobileBrowser,
  );
}

Future<bool> requestBrowserAccelerometerAccess() async {
  return true;
}
