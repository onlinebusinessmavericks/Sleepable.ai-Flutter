# Firebase Messaging
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.cloudmessaging.** { *; }
-dontwarn com.google.android.gms.cloudmessaging.**

# Flutter Plugin Registry (Crucial for MissingPluginException)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.messaging.FlutterFirebaseMessagingService { *; }

# Keep the GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# -----------------------------------------------------
# NEW RULES FROM missing_rules.txt GO HERE:
# -----------------------------------------------------
# (Paste everything you copied from missing_rules.txt right here)
# Fix for Flutter Deferred Components / Play Core Missing Classes
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
# Google Play Billing Library (Crucial for In-App Purchases)
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.internal.play_billing.** { *; }

# Prevent R8/Proguard from stripping the Billing wrapper used by Flutter
-keep class io.flutter.plugins.inapppurchase.** { *; }

# If you use the billing client wrappers directly
-keep class com.hybrid.in_app_purchase_android.** { *; }
# Ensure native library loading remains compatible with 16KB alignment
-keepclassmembers class * {
    native <methods>;
}
-keep class com.google.android.gms.internal.** { *; }