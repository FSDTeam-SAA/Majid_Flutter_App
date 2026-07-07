// String baseUrl = "http://10.10.26.117:5001";

String baseUrl = "https://api.imoscan.com";
//String localBaseUrl = "http://localhost:5001";
final String localBaseUrl = "https://api.imoscan.com";

String apiVersion = "api/v1";
String get baseApiUrl => "$baseUrl/$apiVersion";

class AuthEndpoints {
  static String login = "$baseApiUrl/auth/login";
  static String refreshToken = "$baseApiUrl/auth/refresh-token";
  static String forgotPassword = "$baseApiUrl/auth/forgot-password";
  static String resendForgotOtp = "$baseApiUrl/auth/resend-forgot-otp";
  static String verifyOtp = "$baseApiUrl/auth/verify-otp";
  static String resetPassword = "$baseApiUrl/auth/reset-password";
  static String changePassword = "$baseApiUrl/auth/change-password";
}

class UserEndpoints {
  static String register = "$baseApiUrl/user/register";
  static String verifyEmail = "$baseApiUrl/user/verify-email";
  static String resendOtp = "$baseApiUrl/user/resend-otp";
  static String allUsers = "$baseApiUrl/user/all-users";
  static String myProfile = "$baseApiUrl/user/my-profile";
  static String updateProfile = "$baseApiUrl/user/update-profile";
  static String balanceHistory = "$baseApiUrl/user/balance-history";
}

class ImeiEndpoints {
  static String checkV2 = "$baseApiUrl/imei/check-v2";
  static String services = "$baseApiUrl/imei/services";
  static String servicesSync = "$baseApiUrl/imei/services/sync";
  static String riskAnalysis = "$baseApiUrl/imei/risk-analysis";
  static String deviceAnalysis = "$baseApiUrl/imei/device-analysis";
  static String checkBatch = "$baseApiUrl/imei/check-batch";
  static String history = "$baseApiUrl/imei/history";
}

class InventoryEndpoints {
  static String create = "$baseApiUrl/inventory/create";
  static String all = "$baseApiUrl/inventory";
  static String myInventory = "$baseApiUrl/inventory/my-inventory";
  static String soldItems = "$baseApiUrl/inventory/sold-items";
  static String grouped = "$baseApiUrl/inventory/grouped";
  static String createFromBarcode = "$baseApiUrl/inventory/create-from-barcode";
  static String createFromBarcodeBulk = "$baseApiUrl/inventory/create-from-barcode/bulk";
  static String importCsv = "$baseApiUrl/inventory/import-csv";
  static String importCsvTemplate = "$baseApiUrl/inventory/import-csv/template";
  static String byId(String id) => "$baseApiUrl/inventory/$id";
  static String byUserId(String userId) => "$baseApiUrl/inventory/user/$userId";
  static String byStatus(String status) => "$baseApiUrl/inventory/status/$status";
}

class CategoryEndpoints {
  static String create = "$baseApiUrl/category";
  static String all = "$baseApiUrl/category";
  static String withCount = "$baseApiUrl/category/with-count";
  static String bulkUpdateCount = "$baseApiUrl/category/bulk-update-count";
  static String byId(String id) => "$baseApiUrl/category/$id";
}

class RepairRequestEndpoints {
  static String add = "$baseApiUrl/repair-requests/add";
  static String completed = "$baseApiUrl/repair-requests/completed";
  static String myHistory = "$baseApiUrl/repair-requests/my-history";
  static String byId(String id) => "$baseApiUrl/repair-requests/$id";
  static String updateStatus(String id) => "$baseApiUrl/repair-requests/update-status/$id";
  static String addNote(String id) => "$baseApiUrl/repair-requests/add-note/$id";
  static String technicianNote(String id) => "$baseApiUrl/repair-requests/tech-note/$id";
  static String technicianFeedback(String id) => "$baseApiUrl/repair-requests/technician-feedback/$id";
  static String userDescriptions(String userId) => "$baseApiUrl/repair-requests/user/$userId/descriptions";
}

class InvoiceEndpoints {
  static String create = "$baseApiUrl/invoices/create";
  static String all = "$baseApiUrl/invoices/all";
  static String byShopkeeper(String shopkeeperId) => "$baseApiUrl/invoices/shopkeeper/$shopkeeperId";
  static String byId(String id) => "$baseApiUrl/invoices/$id";
}

class CustomerEndpoints {
  static String create = "$baseApiUrl/customer/create";
  static String all = "$baseApiUrl/customer/all";
  static String byShopkeeper(String shopkeeperId) => "$baseApiUrl/customer/shopkeeper/$shopkeeperId";
  static String update(String id) => "$baseApiUrl/customer/update/$id";
  static String delete(String id) => "$baseApiUrl/customer/delete/$id";
}

class PaymentEndpoints {
  static String createPayment = "$baseApiUrl/payment/create-payment";
  static String myPayments = "$baseApiUrl/payment/my-payments";
  static String allPayments = "$baseApiUrl/payment/all-payments";
  static String webhook = "$baseApiUrl/payment/webhook";
}

class SubscriptionEndpoints {
  static String create = "$baseApiUrl/subscription/create";
  static String all = "$baseApiUrl/subscription/all";
  static String update(String id) => "$baseApiUrl/subscription/update/$id";
}

class DashboardEndpoints {
  static String stats = "$baseApiUrl/dashboard/stats";
}

class NotificationEndpoints {
  static String all = "$baseApiUrl/notification";
  static String shopkeeper = "$baseApiUrl/notification/shopkeeper";
  static String user = "$baseApiUrl/notification/user";
  static String byId(String id) => "$baseApiUrl/notification/$id";
  static String read(String id) => "$baseApiUrl/notification/read/$id";
}

class ReviewEndpoints {
  static String create = "$baseApiUrl/review/create";
  static String byShopkeeper(String shopkeeperId) => "$baseApiUrl/review/shopkeeper/$shopkeeperId";
  static String delete(String reviewId) => "$baseApiUrl/review/$reviewId";
}

class BarcodeEndpoints {
  static String search(String code) => "$baseApiUrl/barcode/$code";
}

class BankDetailsEndpoints {
  static String create = "$baseApiUrl/bank-details/create";
  static String byInvoice(String invoiceId) => "$baseApiUrl/bank-details/invoice/$invoiceId";
  static String byAddedBy(String addedBy) => "$baseApiUrl/bank-details/added-by/$addedBy";
  static String update(String id) => "$baseApiUrl/bank-details/update/$id";
  static String delete(String id) => "$baseApiUrl/bank-details/delete/$id";
}

class CartEndpoints {
  static String create = "$baseApiUrl/add-to-cart/create";
  static String byShopkeeper(String shopkeeperId) => "$baseApiUrl/add-to-cart/shopkeeper/$shopkeeperId";
  static String update(String cartId) => "$baseApiUrl/add-to-cart/update/$cartId";
  static String delete(String cartId) => "$baseApiUrl/add-to-cart/delete/$cartId";
  static String deleteAll(String shopkeeperId) => "$baseApiUrl/add-to-cart/delete-all/shopkeeper/$shopkeeperId";
}

class OcrEndpoints {
  static String extractImei = "$baseApiUrl/ocr/extract-imei";
  static String extractNid = "$baseApiUrl/ocr/extract-nid";
}

class LocationEndpoints {
  static String get = "$baseApiUrl/location";
}

class LowStockAlertEndpoints {
  static String create = "$baseApiUrl/low-stock-alert/create";
  static String myAlert = "$baseApiUrl/low-stock-alert/my-alert";
  static String byId(String id) => "$baseApiUrl/low-stock-alert/$id";
  static String update(String id) => "$baseApiUrl/low-stock-alert/update/$id";
  static String delete(String id) => "$baseApiUrl/low-stock-alert/delete/$id";
}
