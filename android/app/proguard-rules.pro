-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }

-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# flutter_local_notifications plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ForegroundService { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }

# Gson TypeToken (CRITICAL for notification deserialization)
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Gson TypeAdapter patterns
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Mediation Adapters (AppLovin, Amazon, etc.)
-dontwarn com.amazon.privacypass.**
-dontwarn com.iab.omid.**
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**
-keep class com.unity3d.** { *; }
-dontwarn com.unity3d.**
