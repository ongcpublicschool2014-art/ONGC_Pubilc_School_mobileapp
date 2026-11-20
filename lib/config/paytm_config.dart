/// Paytm Payment Gateway configuration (JS Checkout).
///
/// Ported from the KCET admin app. This file holds only NON-SECRET values —
/// the merchant API key (used to sign requests via the Paytm checksum) NEVER
/// lives in the client. It is set as the `PAYTM_MERCHANT_KEY` env var on the
/// Supabase edge functions (`create-paytm-order`, `get-paytm-payment`), exactly
/// the way `RAZORPAY_KEY_SECRET` is kept server-side for the old Razorpay flow.
///
/// The mobile app and the admin app share the same Supabase project
/// (exasnbapvgfeooxyxjas), so those edge functions and their secrets are
/// already deployed — the mobile client only needs these non-secret values.
///
/// The MID and websiteName are not secret — the MID is embedded in the JS
/// Checkout SDK URL the WebView loads, so it is safe here.
class PaytmConfig {
  PaytmConfig._();

  /// Flip to false only when testing against the staging/test environment.
  /// The shared edge functions are currently configured for production.
  static const bool isProduction = true;

  // ---- Merchant IDs (non-secret) ----------------------------------------

  /// Staging/Test MID (only used when [isProduction] is false).
  static const String stagingMid = 'iZngSb05004504656177';

  /// Production MID (live). The single production API/integration MID for this
  /// trust per the Paytm dashboard. Per-unit settlement sub-accounts sit under
  /// this one API MID; all API calls sign with the parent MID below.
  static const String productionMid = 'Krishn06051431858637';

  /// Active MID for the selected environment.
  static String get mid => isProduction ? productionMid : stagingMid;

  // ---- websiteName (non-secret) -----------------------------------------

  /// The `websiteName` Paytm requires when initiating a transaction. Staging
  /// gateway requires 'WEBSTAGING'; production uses 'DEFAULT'. The edge function
  /// actually reads this from its PAYTM_WEBSITE env var; keep the two in sync.
  static const String stagingWebsiteName = 'WEBSTAGING';
  static const String productionWebsiteName = 'DEFAULT';

  /// Active websiteName for the selected environment.
  static String get websiteName =>
      isProduction ? productionWebsiteName : stagingWebsiteName;

  // ---- Gateway hosts -----------------------------------------------------

  /// Base host for the JS Checkout SDK script, the checkout UI, and the native
  /// SDK's showPaymentPage. This is an IOBPAY merchant, so the order + txnToken
  /// are minted on secure.paytmpayments.com (production) / securestage.
  /// paytmpayments.com (staging) — the SDK/checkout MUST use the same host or
  /// the token is rejected ("You are lost in space"). NOT securegw.paytm.in.
  /// The edge function's PAYTM_HOST env must match this selected environment.
  static String get host => isProduction
      ? 'https://secure.paytmpayments.com'
      : 'https://securestage.paytmpayments.com';

  /// Full URL of the merchant-specific JS Checkout SDK for the default MID.
  /// Format: {host}/merchantpgpui/checkoutjs/merchants/{MID}.js
  static String get checkoutJsUrl => checkoutJsUrlFor(mid);

  /// JS Checkout SDK URL for an explicit MID (per-fee-group / per-bank routing).
  static String checkoutJsUrlFor(String forMid) =>
      '$host/merchantpgpui/checkoutjs/merchants/$forMid.js';

  /// Hosts the checkout WebView is allowed to navigate to (defence in depth,
  /// mirrors the Razorpay allowlist). Used by the checkout dialog.
  static Set<String> get allowedHosts => {
        Uri.parse(host).host,
        'securestage.paytmpayments.com',
        'secure.paytmpayments.com',
        'securegw.paytmpayments.com',
      };
}
