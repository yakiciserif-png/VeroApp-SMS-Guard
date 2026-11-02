# VeroApp SMS Guard — Production R8 / ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Android Native Services & BroadcastReceivers
-keep class com.veroapp.smsguard.** { *; }
-dontwarn com.google.android.play.core.**
