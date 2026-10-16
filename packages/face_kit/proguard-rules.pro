# Release (R8) rules. Flutter picks this file up automatically.

# --- Face capture -----------------------------------------------------------
# ONNX Runtime: the app calls libonnxruntime.so through Dart FFI, but the
# native library and its JNI bridge reference these classes by name.
-keep class ai.onnxruntime.** { *; }
-keep class com.gtbluesky.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# ML Kit face detection (models are loaded reflectively by the native side).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face_bundled.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-dontwarn com.google.mlkit.**

# Camera (CameraX), sensors and screen brightness plugins.
-keep class io.flutter.plugins.camerax.** { *; }
-keep class androidx.camera.** { *; }
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-keep class com.aaassseee.screen_brightness_android.** { *; }

# Keep JNI entry points of every native library.
-keepclasseswithmembernames class * {
    native <methods>;
}
