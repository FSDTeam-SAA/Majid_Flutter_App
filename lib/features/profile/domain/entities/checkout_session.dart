/// The Stripe Checkout session created for a subscription payment. Only the
/// [url] is used by the app — it's loaded in an embedded webview.
class CheckoutSession {
  final String url;

  const CheckoutSession({required this.url});
}
