/// Formats inventory attributes returned as either text or a list of values.
String? inventoryAttributeLabel(Object? value) {
  if (value == null) return null;
  if (value is List) {
    return value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .join(', ');
  }
  return value.toString().trim();
}
