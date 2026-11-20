import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/paytm_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/paytm_service.dart';

/// Opens the Paytm JS Checkout in a WebView dialog and resolves once the
/// transaction reaches a terminal state. Returns:
///   'C'  -> captured (success)
///   'F'  -> failed
///   null -> cancelled by the user / WebView could not open
///
/// The dialog polls [PaytmService.verifyPayment] (the server-side Transaction
/// Status API) — it never trusts the browser callback alone. This is the mobile
/// (webview_flutter) counterpart of the admin app's Windows checkout dialog.
Future<String?> showPaytmCheckout(
  BuildContext context, {
  required PaytmOrder order,
  required double amount,
  String studentName = '',
  String studentMobile = '',
  String studentEmail = '',
  String merchantName = '',
  Duration pollInterval = const Duration(seconds: 3),
  Duration pollMaxDuration = const Duration(minutes: 10),
}) async {
  final completer = Completer<String?>();
  Timer? pollTimer;
  WebViewController controller;

  try {
    final html = PaytmService.buildCheckoutHtml(
      order: order,
      studentName: studentName,
      studentMobile: studentMobile,
      studentEmail: studentEmail,
      merchantName: merchantName,
    );

    final allowed = PaytmConfig.allowedHosts;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // Capture JS diagnostics the checkout HTML posts so a stuck/blank
      // checkout shows its real cause in the run log.
      ..addJavaScriptChannel(
        'PaytmDiag',
        onMessageReceived: (msg) => debugPrint('PAYTM WEBVIEW: ${msg.message}'),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              final scheme = uri.scheme.toLowerCase();
              const webSchemes = {'http', 'https', 'file', 'about', 'data', 'blob'};
              // Non-web schemes (upi:, intent:, tez:, phonepe:, paytmmp:, gpay:,
              // …) are UPI / payment-app deep links — a WebView can't open them,
              // so hand them to the OS to launch the installed UPI app.
              if (scheme.isNotEmpty && !webSchemes.contains(scheme)) {
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Paytm: could not launch $scheme app: $e');
                }
                return NavigationDecision.prevent;
              }
              // Defence-in-depth: log unexpected https hosts (Paytm may redirect
              // through bank/UPI hosts, so we warn rather than block).
              if (scheme != 'file' &&
                  scheme != 'about' &&
                  scheme != 'data' &&
                  uri.host.isNotEmpty &&
                  !allowed.contains(uri.host)) {
                debugPrint('Paytm webview navigated to: ${uri.host}');
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load with baseUrl = the Paytm host so the checkout page shares the SDK's
    // origin — the CheckoutJS and its XHRs then run same-origin (a file:// or
    // about:blank origin would get those cross-origin calls blocked on Android).
    await controller.loadHtmlString(html, baseUrl: PaytmConfig.host);
  } catch (e) {
    // pollTimer isn't started until after this try block, so nothing to cancel.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not open the Paytm payment window. Please retry.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  // Poll the server-side status API until a terminal state or timeout.
  final pollStarted = DateTime.now();
  pollTimer = Timer.periodic(pollInterval, (timer) async {
    if (DateTime.now().difference(pollStarted) > pollMaxDuration) {
      timer.cancel();
      try {
        final s = await PaytmService.verifyPayment(order.orderId, mid: order.mid);
        if (!completer.isCompleted) {
          completer.complete(s.isCaptured ? 'C' : 'F');
        }
      } catch (_) {
        if (!completer.isCompleted) completer.complete('F');
      }
      return;
    }
    try {
      final s = await PaytmService.verifyPayment(order.orderId, mid: order.mid);
      if (s.isCaptured) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete('C');
      } else if (s.isFailed) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete('F');
      }
    } catch (_) {
      // transient — keep polling
    }
  });

  BuildContext? dialogCtx;
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogCtx = ctx;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 500,
            height: 620,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Paytm Payment  •  ₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          // Last-chance authoritative check before treating as
                          // cancelled — the txn may have just succeeded.
                          pollTimer?.cancel();
                          try {
                            final s = await PaytmService.verifyPayment(
                                order.orderId,
                                mid: order.mid);
                            if (s.isCaptured) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!completer.isCompleted) completer.complete('C');
                              return;
                            }
                          } catch (_) {}
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!completer.isCompleted) completer.complete(null);
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(child: WebViewWidget(controller: controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  final result = await completer.future;

  if (dialogCtx != null && dialogCtx!.mounted) {
    final nav = Navigator.maybeOf(dialogCtx!);
    if (nav != null && nav.canPop()) nav.pop();
  }

  pollTimer.cancel();
  return result;
}
