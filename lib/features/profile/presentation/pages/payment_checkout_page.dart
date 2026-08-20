import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/utils/colors.dart';

/// Opens a Stripe Checkout session inside the app and reports back whether
/// the user completed or cancelled the payment, based on the redirect leg
/// (any navigation away from checkout.stripe.com).
class PaymentCheckoutPage extends StatefulWidget {
  final String checkoutUrl;

  const PaymentCheckoutPage({super.key, required this.checkoutUrl});

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final isStripeCheckout =
                uri?.host.contains('checkout.stripe.com') ?? true;
            if (!isStripeCheckout && !_resolved) {
              _resolved = true;
              final isSuccess = request.url.toLowerCase().contains('success');
              Navigator.of(context).pop(isSuccess);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Complete Payment', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}
