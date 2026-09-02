# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods for JNI and Rust bridge
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Linko application classes
-keep class com.linko.app.** { *; }

# Allow R8 full optimization
-dontwarn javax.annotation.**
-dontwarn kotlin.**
-dontwarn com.google.android.play.core.**
