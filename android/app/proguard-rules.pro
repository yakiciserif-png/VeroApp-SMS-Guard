# VeroApp SMS Guard — Production R8 / ProGuard Optimization & Obfuscation Rules

# Flutter & Dart Runtime
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep VeroApp Native Kotlin Services & BroadcastReceivers
-keep class com.veroapp.smsguard.** { *; }
-keepclassmembers class com.veroapp.smsguard.** { *; }

# Native SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }
-keepclassmembers class com.tekartik.sqflite.** { *; }

# TensorFlow Lite & Neural Networks
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Google Play Billing & In-App Purchases
-keep class com.android.billingclient.** { *; }
-keepclassmembers class com.android.billingclient.** { *; }
-dontwarn com.google.android.play.core.**

# Cryptography & Ed25519 Serialization
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep JSON and Data Model fields accessed via reflection
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
