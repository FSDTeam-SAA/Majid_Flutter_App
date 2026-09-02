/// Everything the Smart Invoice needs about the scanned device.
///
/// Filled straight from the device report, so the shopkeeper never retypes the
/// model, IMEI or verification status.
class SmartInvoiceDevice {
  final String itemName;
  final String imei;
  final String serial;
  final String warranty;
  final String purchaseDate;
  final String warrantyType;

  // Verification column
  final String blacklist;
  final String simLock;
  final String activation;

  // IMEI API response summary
  final String coverage;
  final String registration;
  final String replaced;
  final String openRepair;

  /// 0-100.
  final int riskScore;
  final String aiSummary;

  const SmartInvoiceDevice({
    required this.itemName,
    required this.imei,
    this.serial = 'N/A',
    this.warranty = 'N/A',
    this.purchaseDate = 'N/A',
    this.warrantyType = 'N/A',
    this.blacklist = 'N/A',
    this.simLock = 'N/A',
    this.activation = 'N/A',
    this.coverage = 'N/A',
    this.registration = 'N/A',
    this.replaced = 'N/A',
    this.openRepair = 'N/A',
    this.riskScore = 0,
    this.aiSummary = 'N/A',
  });
}

/// The details the website's Smart Invoice dialog asks for - the only things
/// that cannot be taken from the scan.
class SmartInvoiceCustomer {
  final String fullName;
  final String email;
  final String buildingNumber;
  final String street;
  final String postCode;
  final String country;
  final String phone;
  final String customerId;

  /// Set when a saved customer was picked, so the invoice links to them
  /// instead of creating a duplicate.
  final String? existingCustomerId;
  final String currencyCode;
  final String currencySymbol;
  final double amount;
  final String paymentMethod;
  final bool isPaid;

  const SmartInvoiceCustomer({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.currencyCode,
    required this.currencySymbol,
    required this.amount,
    required this.paymentMethod,
    required this.isPaid,
    this.buildingNumber = '',
    this.street = '',
    this.postCode = '',
    this.country = '',
    this.customerId = '',
    this.existingCustomerId,
  });

  /// `UNIT22 Havering, RM7 8BE, United Kingdom`
  String get addressLine => [
    [buildingNumber, street].where((v) => v.trim().isNotEmpty).join(' '),
    postCode,
    country,
  ].where((v) => v.trim().isNotEmpty).join(', ');
}
