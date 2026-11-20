import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/online_payment_service.dart';

/// Opens the school's payment gateway (Setup > Payment Gateways on the office
/// app) for [order] and returns the SERVER's verdict:
///   C paid and receipted, F not paid, X paid but the office must raise the
///   receipt, I not decided yet (the server receipts it on its own later).
/// null only when nothing could be opened.
///
/// Paytm uses the Paytm app / native SDK; every other gateway opens its own
/// page in a WebView. Either way the answer comes from pay-status, which asks
/// the gateway with the school's key -- nothing the page says is trusted.
Future<OnlinePayResult?> openGatewayCheckout(
  BuildContext context, {
  required OnlineOrder order,
  required String gatewayName,
  String payerName = '',
  String payerMobile = '',
  String merchantName = '',
}) async {
  if (order.checkout['kind'] == 'paytm') return _paytmNative(order);
  return Navigator.of(context).push<OnlinePayResult?>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _GatewayCheckoutPage(
      order: order,
      gatewayName: gatewayName,
      payerName: payerName,
      payerMobile: payerMobile,
      merchantName: merchantName,
    ),
  ));
}

Future<OnlinePayResult?> _ask(String orderId, {bool cancel = false}) async {
  try {
    return await OnlinePaymentService.status(orderId, cancel: cancel);
  } catch (e) {
    debugPrint('pay-status $orderId: $e');
    return null;
  }
}

/// Paytm: the order was created for the app channel (WAP + Paytm's callback
/// URL), which is what the All-in-One SDK expects.
Future<OnlinePayResult?> _paytmNative(OnlineOrder order) async {
  final c = order.checkout;
  final orderId = '${c['order_id']}';
  var cancelled = false;
  try {
    await AllInOneSdk.startTransaction(
      '${c['mid']}',
      orderId,
      '${c['amount']}',
      '${c['txn_token']}',
      '${c['host']}/theia/paytmCallback?ORDER_ID=$orderId',
      order.mode == 'TEST', // isStaging
      true, // restrictAppInvoke
    );
  } catch (e) {
    // The SDK's answer is advisory; a back press is the only thing we use it
    // for, and even then the server asks Paytm before cancelling anything.
    final m = e.toString().toLowerCase();
    cancelled = m.contains('cancel') || m.contains('back');
    debugPrint('Paytm SDK: $e');
  }
  // Most payments settle in a few seconds.
  for (var i = 0; i < 6; i++) {
    final r = await _ask(orderId);
    if (r != null && r.isFinal) return r;
    await Future.delayed(const Duration(milliseconds: 1500));
  }
  if (cancelled) return await _ask(orderId, cancel: true) ?? const OnlinePayResult('I');
  return const OnlinePayResult('I');
}

class _GatewayCheckoutPage extends StatefulWidget {
  final OnlineOrder order;
  final String gatewayName, payerName, payerMobile, merchantName;
  const _GatewayCheckoutPage({
    required this.order,
    required this.gatewayName,
    required this.payerName,
    required this.payerMobile,
    required this.merchantName,
  });
  @override
  State<_GatewayCheckoutPage> createState() => _GatewayCheckoutPageState();
}

class _GatewayCheckoutPageState extends State<_GatewayCheckoutPage> {
  late final WebViewController _web;
  Timer? _timer;
  bool _polling = false, _done = false;

  /// The payer has done something at the gateway (paid, left for a UPI app or
  /// a bank page). Leaving after that is no longer free.
  bool _started = false;
  String? _failure;
  final DateTime _openedAt = DateTime.now();

  String get _orderId => widget.order.orderId;

  @override
  void initState() {
    super.initState();
    final kind = '${widget.order.checkout['kind']}';
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('PayBridge', onMessageReceived: (m) => _onMessage(m.message))
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: _onNavigate));
    if (kind == 'redirect') {
      _web.loadRequest(Uri.parse('${widget.order.checkout['url']}'));
    } else {
      // An https base gives the page a real origin for the gateway's script.
      _web.loadHtmlString(_checkoutHtml(), baseUrl: 'https://localhost/');
    }
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish(OnlinePayResult? r) {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop(r);
  }

  void _onMessage(String m) {
    debugPrint('GATEWAY WEBVIEW: $m');
    if (m.startsWith('paid')) {
      _started = true;
      _poll();
    } else if (m.startsWith('failed')) {
      _poll();
    } else if (m.startsWith('dismissed')) {
      _close();
    }
  }

  Future<NavigationDecision> _onNavigate(NavigationRequest req) async {
    final uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.navigate;
    final scheme = uri.scheme.toLowerCase();
    const web = {'http', 'https', 'about', 'data', 'blob'};
    if (scheme.isNotEmpty && !web.contains(scheme)) {
      // upi:, intent:, tez:, phonepe:, paytmmp: ... -- a UPI app.
      _started = true;
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('could not open $scheme app: $e');
      }
      return NavigationDecision.prevent;
    }
    if (uri.path.endsWith('/pay-return')) {
      _started = true;
      _poll();
    } else if (uri.host != 'localhost' && req.url != '${widget.order.checkout['url']}') {
      _started = true;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _poll() async {
    if (_polling || _done) return;
    if (DateTime.now().difference(_openedAt) > const Duration(minutes: 15)) {
      _finish(await _ask(_orderId) ?? const OnlinePayResult('I'));
      return;
    }
    _polling = true;
    try {
      final r = await _ask(_orderId);
      if (r == null || !r.isFinal || _done) return;
      if (r.status == 'F' && _started) {
        _timer?.cancel();
        if (mounted) setState(() => _failure = 'The payment did not go through.');
        return;
      }
      _finish(r);
    } finally {
      _polling = false;
    }
  }

  /// Close / back. Asks once more; a payment the payer acted on can only be
  /// left deliberately, and one never started is cancelled so a retry works.
  Future<void> _close() async {
    if (_done) return;
    final r = await _ask(_orderId);
    if (r != null && r.isFinal) {
      _finish(r);
      return;
    }
    if (_started) {
      if (!mounted) return;
      final leave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: const Text('Payment in progress'),
          content: const Text(
              'Your bank has not confirmed this payment yet.\n\n'
              'If you leave now and the amount is debited, the receipt appears in '
              'History within a few minutes. Please do NOT pay again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep waiting')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Leave')),
          ],
        ),
      );
      if (leave != true) return;
      _finish(r ?? const OnlinePayResult('I'));
      return;
    }
    _finish(await _ask(_orderId, cancel: true) ?? const OnlinePayResult('I'));
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.gatewayName}  ₹${o.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (o.mode == 'TEST')
              const Text('TEST MODE - no real money is taken', style: TextStyle(fontSize: 11)),
          ]),
        ),
        body: _failure == null
            ? WebViewWidget(controller: _web)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  const Text('Payment not completed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(_failure!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text(
                    'No receipt has been raised. If the amount was debited, the bank refunds '
                    'it, or the receipt appears in History once it settles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _finish(const OnlinePayResult('F')),
                    child: const Text('Close'),
                  ),
                ]),
              ),
      ),
    );
  }

  String _js(String s) => jsonEncode(s);

  /// Local page that opens the gateway's own checkout script.
  String _checkoutHtml() {
    final c = widget.order.checkout;
    final merchant = widget.merchantName.trim().isEmpty ? 'School Fees' : widget.merchantName.trim();
    String sdk, script;
    switch ('${c['kind']}') {
      case 'razorpay':
        sdk = 'https://checkout.razorpay.com/v1/checkout.js';
        script = '''
function onSdk() {
  if (!window.Razorpay) { show('The payment page did not load. Go back and retry.'); return; }
  var rzp = new Razorpay({
    key: ${_js('${c['key_id']}')}, order_id: ${_js('${c['gw_order_id']}')},
    amount: ${(c['amount_paise'] as num?)?.toInt() ?? 0}, currency: "INR",
    name: ${_js(merchant)}, description: ${_js('Fee payment ${c['order_id']}')},
    prefill: { name: ${_js(widget.payerName)}, contact: ${_js(widget.payerMobile)} },
    handler: function(r) { post('paid ' + (r && r.razorpay_payment_id || '')); show('Payment received. Raising the receipt...'); },
    modal: { ondismiss: function() { post('dismissed'); show('Checking...'); } }
  });
  rzp.on('payment.failed', function(r) { post('failed ' + (r && r.error ? r.error.description : '')); });
  rzp.open();
}''';
        break;
      case 'cashfree':
        sdk = 'https://sdk.cashfree.com/js/v3/cashfree.js';
        script = '''
function onSdk() {
  if (!window.Cashfree) { show('The payment page did not load. Go back and retry.'); return; }
  Cashfree({ mode: ${_js('${c['env']}')} }).checkout({ paymentSessionId: ${_js('${c['payment_session_id']}')}, redirectTarget: "_self" });
}''';
        break;
      default:
        sdk = '';
        script = 'function onSdk() { show("This payment method is not supported in the app."); }';
    }
    return '''
<!DOCTYPE html>
<html><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{font-family:sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;color:#555}</style>
<script>
function post(m){ try { PayBridge.postMessage(String(m)); } catch(e){} }
window.onerror = function(msg, src, line){ post('JSERR: ' + msg + ' @ ' + (src||'') + ':' + (line||'')); };
function show(m){ var el = document.getElementById('status'); if (el) el.textContent = m; }
$script
</script>
<script src="$sdk" onload="onSdk()" onerror="show('Could not reach the payment gateway. Check your internet and retry.')"></script>
</head><body><p id="status">Opening the payment page...</p></body></html>
''';
  }
}
