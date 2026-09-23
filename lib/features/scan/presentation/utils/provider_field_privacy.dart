/// Provider response metadata that belongs to the business/API account and
/// must never appear in a customer-facing device report.
bool isCustomerSafeProviderField(String key) {
  final normalized = key
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  if (normalized.isEmpty) return false;

  const blockedExact = {
    'result',
    'image',
    'balance',
    'price',
    'cost',
    'id',
    'status',
    'ip',
    'ip_address',
    'api_ip',
    'api_key',
    'apikey',
    'token',
    'access_token',
    'secret',
  };
  if (blockedExact.contains(normalized)) return false;

  const blockedFragments = {
    'account_balance',
    'available_balance',
    'provider_balance',
    'credit_balance',
    'service_price',
    'provider_price',
    'original_price',
    'purchase_price',
    'wholesale_price',
    'service_cost',
    'provider_cost',
    'request_id',
    'transaction_id',
    'api_token',
    'auth_token',
  };
  return !blockedFragments.any(normalized.contains);
}
