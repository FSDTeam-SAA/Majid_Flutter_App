import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/payment_repository.dart';

Payment _paymentFromJson(Map<String, dynamic> json) {
  final id = json['_id']?.toString() ?? json['transactionId']?.toString() ?? '';
  return Payment(
    id: id,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: json['status']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

SubscriptionPlan _subscriptionPlanFromJson(Map<String, dynamic> json) {
  final rawFeatures = json['features'];
  final includedFeatures = rawFeatures is List
      ? rawFeatures
          .whereType<Map>()
          .where((f) => f['included'] == true)
          .map((f) => f['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList()
      : <String>[];

  return SubscriptionPlan(
    id: json['_id']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    priceLabel: json['priceLabel']?.toString(),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    customPricing: json['customPricing'] == true,
    isPopular: json['isPopular'] == true,
    discount: json['discount'] as num?,
    ctaText: json['ctaText']?.toString(),
    includedFeatures: includedFeatures,
  );
}

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiClient _api;

  PaymentRepositoryImpl(this._api);

  @override
  Future<List<Payment>> getMyPayments() async {
    final res = await _api.get(PaymentEndpoints.myPayments);
    final data = res.data['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((item) => _paymentFromJson(Map<String, dynamic>.from(item))).toList();
  }

  @override
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final res = await _api.get(SubscriptionEndpoints.all);
    final data = res.data['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((item) => _subscriptionPlanFromJson(Map<String, dynamic>.from(item))).toList();
  }

  @override
  Future<CheckoutSession> createPayment({
    required double amount,
    String? subscriptionId,
  }) async {
    final res = await _api.post(
      PaymentEndpoints.createPayment,
      data: {
        'amount': amount,
        if (subscriptionId != null && subscriptionId.isNotEmpty) 'subscriptionId': subscriptionId,
      },
    );
    final data = Map<String, dynamic>.from(res.data['data']);
    return CheckoutSession(url: data['url']?.toString() ?? '');
  }
}
