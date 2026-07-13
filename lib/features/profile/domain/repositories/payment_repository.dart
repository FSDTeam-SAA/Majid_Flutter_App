import '../entities/checkout_session.dart';
import '../entities/payment.dart';
import '../entities/subscription_plan.dart';

abstract class PaymentRepository {
  /// Fetches the current user's payment/transaction history.
  Future<List<Payment>> getMyPayments();

  /// Fetches the available subscription plans.
  Future<List<SubscriptionPlan>> getSubscriptionPlans();

  /// Creates a payment (optionally against a subscription plan) and returns
  /// the Stripe Checkout session to complete it.
  Future<CheckoutSession> createPayment({
    required double amount,
    String? subscriptionId,
  });
}
