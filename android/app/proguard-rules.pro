-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# smart_auth (pinput dependency) - Google Play Services Credentials
-dontwarn com.google.android.gms.auth.api.credentials.**

# Paytm All-in-One SDK (paytm_allinonesdk / com.paytm.pgsdk) — keep through R8
-keep class net.one97.paytm.** { *; }
-keep class com.paytm.** { *; }
-dontwarn net.one97.paytm.**
-dontwarn com.paytm.**
