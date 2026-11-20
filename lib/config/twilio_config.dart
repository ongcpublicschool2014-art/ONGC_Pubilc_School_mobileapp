/// Twilio SMS configuration
/// IMPORTANT: In production, use environment variables via --dart-define
/// flutter run --dart-define=TWILIO_ACCOUNT_SID=xxx --dart-define=TWILIO_AUTH_TOKEN=xxx --dart-define=TWILIO_PHONE_NUMBER=xxx
class TwilioConfig {
  TwilioConfig._();

  /// Twilio Account SID
  static const String accountSid = String.fromEnvironment(
    'TWILIO_ACCOUNT_SID',
    defaultValue: '',
  );

  /// Twilio Auth Token
  static const String authToken = String.fromEnvironment(
    'TWILIO_AUTH_TOKEN',
    defaultValue: '',
  );

  /// Twilio Phone Number (with country code, e.g., +1234567890)
  static const String twilioNumber = String.fromEnvironment(
    'TWILIO_PHONE_NUMBER',
    defaultValue: '',
  );

  /// Check if Twilio is properly configured
  static bool get isConfigured =>
      accountSid.isNotEmpty &&
      authToken.isNotEmpty &&
      twilioNumber.isNotEmpty;
}
