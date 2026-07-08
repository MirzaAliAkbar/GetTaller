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

-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
