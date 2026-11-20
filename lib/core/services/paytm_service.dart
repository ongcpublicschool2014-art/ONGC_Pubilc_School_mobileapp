import 'package:flutter/foundation.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
import '../../config/paytm_config.dart';
import 'supabase_service.dart';

/// Result of a Paytm "Initiate Transaction" call.
class PaytmOrder {
  final String orderId;
  final String txnToken;
  final String amount; // rupees, 2 decimals (e.g. "1500.00")
  final String mid; // the merchant the order was created under

  const PaytmOrder({
    required this.orderId,
    required this.txnToken,
    required this.amount,
    required this.mid,
  });
}

/// Status of a Paytm transaction, normalised to the same vocabulary the
/// existing Razorpay polling loop uses.
class PaytmStatus {
  /// 'captured' | 'failed' | 'pending'
  final String status;

  /// Paytm txnId — stored as `payreference` on success.
  final String? paymentId;

  const PaytmStatus({required this.status, this.paymentId});

  bool get isCaptured => status == 'captured';
  bool get isFailed => status == 'failed';
}

/// Client-side helper for the Paytm JS Checkout flow (ported from the KCET
/// admin app for the mobile app).
///
/// All signing happens server-side in the `create-paytm-order` and
/// `get-paytm-payment` edge functions (shared Supabase project) — this service
/// only orchestrates the calls and builds the checkout HTML the WebView renders.
class PaytmService {
  PaytmService._();

  /// Initiate a transaction. The payment row (status 'I') must already exist;
  /// pass its [payId]. Returns the order id + txnToken for the checkout page.
  /// [mid] optionally overrides the merchant (per-bank routing); when null the
  /// edge function falls back to the default MID.
  static Future<PaytmOrder> createOrder({
    required int payId,
    required double amount,
    String? custId,
    String? orderId,
    String? mid,
    String? channelId,
  }) async {
    // Paytm rejects a reused order id (resultCode 325 "duplicate order id") and
    // remembers every id forever. A bare `PAY-<pay_id>` collides whenever a
    // pay_id recurs (e.g. across test runs) or an attempt is retried, so make
    // each attempt globally unique. The edge function persists this as
    // `payorderid`, and verifyPayment uses the same id — so it stays consistent.
    final effectiveOrderId =
        orderId ?? 'PAY-${payId}t${DateTime.now().millisecondsSinceEpoch}';
    final resp = await SupabaseService.client.functions.invoke(
      'create-paytm-order',
      body: {
        'amount': amount,
        'pay_id': payId,
        if (custId != null) 'cust_id': custId,
        'order_id': effectiveOrderId,
        if (mid != null) 'mid': mid,
        // "WAP" makes Paytm create the order on the mobile channel, which
        // enables UPI Intent (direct-to-UPI-app) in the checkout. Omitted → WEB.
        if (channelId != null) 'channel_id': channelId,
      },
    );

    final data = resp.data is Map<String, dynamic>
        ? resp.data as Map<String, dynamic>
        : <String, dynamic>{};

    final token = data['txn_token']?.toString();
    final order = data['order_id']?.toString();
    if (token == null || token.isEmpty || order == null || order.isEmpty) {
      throw Exception(
        'Paytm order initiation failed: ${data['error'] ?? data['result_info'] ?? data}',
      );
    }

    return PaytmOrder(
      orderId: order,
      txnToken: token,
      amount: data['amount']?.toString() ?? amount.toStringAsFixed(2),
      mid: data['mid']?.toString() ?? mid ?? PaytmConfig.mid,
    );
  }

  /// Authoritative status check via the Transaction Status API. [mid] must be
  /// the merchant the order was created under (PaytmOrder.mid).
  static Future<PaytmStatus> verifyPayment(String orderId, {String? mid}) async {
    final resp = await SupabaseService.client.functions.invoke(
      'get-paytm-payment',
      body: {
        'order_id': orderId,
        if (mid != null) 'mid': mid,
      },
    );
    final data = resp.data is Map<String, dynamic>
        ? resp.data as Map<String, dynamic>
        : <String, dynamic>{};
    final status = data['status']?.toString() ?? 'pending';
    final paymentId = data['payment_id']?.toString();
    return PaytmStatus(
      status: status,
      paymentId: (paymentId != null && paymentId.isNotEmpty) ? paymentId : null,
    );
  }

  /// Launch the native Paytm All-in-One SDK checkout (Android). The returned
  /// map is ADVISORY — always confirm the real outcome server-side via
  /// [confirmOutcome] / [verifyPayment]. Throws a PlatformException on
  /// cancel/error; treat that as "verify server-side", not a definite failure.
  static Future<Map<dynamic, dynamic>?> launchSdk(PaytmOrder order) {
    return AllInOneSdk.startTransaction(
      order.mid,
      order.orderId,
      order.amount,
      order.txnToken,
      '${PaytmConfig.host}/theia/paytmCallback?ORDER_ID=${order.orderId}',
      !PaytmConfig.isProduction, // isStaging: false in production
      true, // restrictAppInvoke
    );
  }

  /// Authoritative outcome via the server-side status API. Polls FAST at first
  /// (most UPI/card txns settle in 1-3s) then backs off, so success shows in
  /// ~1-2s in the common case.
  ///
  /// Returns 'C' (captured) | 'F' (failed) | **null (STILL PENDING)**.
  ///
  /// null is NOT a failure. A payment Paytm has not decided on is the one that
  /// most often succeeds a moment later -- the bank has already debited. The
  /// caller must leave the row 'I' for the stuck-payment sweep and must never
  /// write it off as failed.
  ///
  /// [maxWait] is 8s, not 20s. Past a few seconds more polling almost never
  /// changes the answer, and every extra second is a parent watching a spinner
  /// after their money has already left. Anything undecided by then is handed
  /// to the background resolver, which is better at waiting than a person is.
  static Future<String?> confirmOutcome(
    PaytmOrder order, {
    Duration maxWait = const Duration(seconds: 8),
  }) async {
    // Gaps between checks (the first check runs immediately). Small early gaps
    // catch a quick settlement fast; later gaps widen to avoid hammering.
    const gaps = <Duration>[
      Duration(milliseconds: 700),
      Duration(milliseconds: 800),
      Duration(seconds: 1),
      Duration(milliseconds: 1500),
      Duration(seconds: 2),
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 3),
    ];
    final deadline = DateTime.now().add(maxWait);
    for (var i = 0;; i++) {
      try {
        final s = await verifyPayment(order.orderId, mid: order.mid);
        if (s.isCaptured) return 'C';
        if (s.isFailed) return 'F';
      } catch (_) {
        // transient network error — keep polling
      }
      if (!DateTime.now().isBefore(deadline)) return null;
      await Future.delayed(i < gaps.length ? gaps[i] : const Duration(seconds: 3));
    }
  }

  /// Build the local checkout HTML loaded into the WebView. The merchant JS
  /// Checkout SDK is fetched from Paytm; we only hand it the txnToken/orderId.
  ///
  /// Diagnostics are posted to the `PaytmDiag` JavaScript channel that the
  /// mobile checkout dialog registers (webview_flutter), instead of the
  /// Windows-only `window.chrome.webview` used by the admin desktop app.
  static String buildCheckoutHtml({
    required PaytmOrder order,
    String studentName = '',
    String studentMobile = '',
    String studentEmail = '',
    String merchantName = 'FIT School',
  }) {
    final mid = order.mid;
    final sdkUrl = PaytmConfig.checkoutJsUrlFor(mid);
    final safeName = studentName.replaceAll("'", "\\'");
    final rawMerchant = merchantName.trim().isEmpty ? 'FIT School' : merchantName.trim();
    final safeMerchant = rawMerchant
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll(RegExp(r'[\r\n]+'), ' ');

    return '''
<!DOCTYPE html>
<html>
<head>
  <title>$rawMerchant - Fee Payment</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
    .container { text-align: center; padding: 40px; }
    .info { color: #666; margin-top: 10px; }
  </style>
  <!-- Define the handler BEFORE the SDK <script> so it exists when onload fires. -->
  <script type="application/javascript">
    // Forward JS errors/diagnostics to Flutter (PaytmDiag channel) so a stuck
    // checkout can be diagnosed from the run log.
    function post(m) { try { if (window.PaytmDiag && window.PaytmDiag.postMessage) { window.PaytmDiag.postMessage(String(m)); } } catch (e) {} }
    window.onerror = function(msg, src, line) { post('JSERR: ' + msg + ' @ ' + (src || '') + ':' + (line || '')); };
    function showStatus(msg) {
      var el = document.getElementById('status');
      if (el) el.innerHTML = '<p class="info">' + msg + '</p>';
    }
    function onScriptLoad() {
      post('onScriptLoad; hasCheckoutJS=' + !!(window.Paytm && window.Paytm.CheckoutJS));
      var config = {
        "root": "",
        "flow": "DEFAULT",
        "merchant": { "mid": "$mid", "name": "$safeMerchant", "redirect": false },
        "data": {
          "orderId": "${order.orderId}",
          "token": "${order.txnToken}",
          "tokenType": "TXN_TOKEN",
          "amount": "${order.amount}",
          "userDetail": {
            "name": "$safeName",
            "mobile": "$studentMobile",
            "email": "$studentEmail"
          }
        },
        "handler": {
          "notifyMerchant": function(eventName, data) {
            console.log("notifyMerchant", eventName, data);
          },
          // Required when merchant.redirect = false. The Flutter side polls
          // get-paytm-payment for the authoritative result and closes the
          // dialog, so here we just surface progress and close the checkout UI.
          "transactionStatus": function(paymentStatus) {
            console.log("transactionStatus", paymentStatus);
            showStatus('Payment submitted. Verifying with the bank...');
            try { window.Paytm.CheckoutJS.close(); } catch (e) {}
          }
        }
      };
      if (window.Paytm && window.Paytm.CheckoutJS) {
        window.Paytm.CheckoutJS.onLoad(function checkoutReady() {
          post('onLoad fired; calling init');
          window.Paytm.CheckoutJS.init(config)
            .then(function onSuccess() { post('init OK; invoking'); window.Paytm.CheckoutJS.invoke(); post('invoke called'); })
            .catch(function onError(error) {
              post('INIT_ERR: ' + (error && error.message ? error.message : JSON.stringify(error)));
              showStatus('Unable to open Paytm checkout: ' + error);
              console.error("CheckoutJS init error", error);
            });
        });
      } else {
        post('SDK not loaded (window.Paytm.CheckoutJS missing)');
        showStatus('Paytm SDK did not load. Please close and retry.');
      }
    }
  </script>
  <script type="application/javascript" crossorigin="anonymous" src="$sdkUrl" onload="onScriptLoad();"></script>
</head>
<body>
  <div class="container" id="status">
    <p class="info">Opening Paytm Checkout...</p>
  </div>
</body>
</html>
''';
  }

  /// Convenience: is the gateway configured enough to attempt a payment?
  static bool get isConfigured {
    final ok = PaytmConfig.mid.isNotEmpty;
    if (!ok) debugPrint('PaytmService: MID is empty — check PaytmConfig.');
    return ok;
  }
}
