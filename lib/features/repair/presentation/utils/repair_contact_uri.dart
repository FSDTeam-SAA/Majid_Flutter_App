/// Customer-contact URIs used by repair status actions.
///
/// Values are encoded with [Uri.encodeComponent] instead of
/// [Uri.queryParameters]. The latter represents spaces as `+`, which some
/// iOS composers show literally in the drafted customer message.
Uri repairSmsUri(String phone, String message) =>
    Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');

Uri repairWhatsAppUri(String phone, String message) =>
    Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

Uri repairEmailUri(
  String email, {
  required String subject,
  required String body,
}) => Uri.parse(
  'mailto:${Uri.encodeComponent(email)}'
  '?subject=${Uri.encodeComponent(subject)}'
  '&body=${Uri.encodeComponent(body)}',
);
