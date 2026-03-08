import 'dart:io' show Platform;

import 'runtime_context.dart';

RuntimeContext detectRuntimeContext() {
  if (Platform.isAndroid) {
    return const RuntimeContext(
      mode: RuntimeMode.androidApp,
      motionSupport: MotionSupport.deviceAccelerometer,
      needsBrowserAccelerometerPrompt: false,
    );
  }

  if (Platform.isIOS) {
    return const RuntimeContext(
      mode: RuntimeMode.iosApp,
      motionSupport: MotionSupport.deviceAccelerometer,
      needsBrowserAccelerometerPrompt: false,
    );
  }

  return const RuntimeContext(
    mode: RuntimeMode.other,
    motionSupport: MotionSupport.none,
    needsBrowserAccelerometerPrompt: false,
  );
}

Future<bool> requestBrowserAccelerometerAccess() async {
  return false;
}
