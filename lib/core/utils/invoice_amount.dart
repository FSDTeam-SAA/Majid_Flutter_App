/// Keep displayed invoice amounts and recorded payments at the same precision.
/// Invalid numbers remain invalid so the caller can reject them before saving.
double invoiceMoney(double amount) {
  final scaled = amount * 100;
  return scaled.isFinite ? scaled.round() / 100 : amount;
}
