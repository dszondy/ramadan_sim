import 'runtime_context.dart';

RuntimeContext detectRuntimeContext() {
  return const RuntimeContext(
    mode: RuntimeMode.other,
    motionSupport: MotionSupport.none,
    needsBrowserAccelerometerPrompt: false,
  );
}

Future<bool> requestBrowserAccelerometerAccess() async {
  return false;
}
