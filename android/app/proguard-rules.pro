# Release (R8) rules. Flutter picks this file up automatically.
#
# Keep only what is looked up by name at runtime. Whole libraries kept with
# "-keep class some.library.** { *; }" stop R8 from shrinking and optimising
# them, which Play flags; CameraX, ML Kit and Play services ship their own
# rules for what they need, and Flutter plugins are reached from
# GeneratedPluginRegistrant, which R8 can see.

# --- Face capture -----------------------------------------------------------
# ONNX Runtime: the app calls libonnxruntime.so through Dart FFI, and the
# native library and its JNI bridge reference these classes by name. The
# library ships no rules of its own.
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# ML Kit's optional pieces that aren't on the classpath.
-dontwarn com.google.mlkit.**

# Keep JNI entry points of every native library.
-keepclasseswithmembernames class * {
    native <methods>;
}
