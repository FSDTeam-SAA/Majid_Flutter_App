import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/outstanding_invoice.dart';

Future<List<OutstandingInvoice>> loadCustomerBalances(
  ApiClient api,
  String customerId,
) async {
  final response = await api.get(
    '$baseApiUrl/invoices/customer/${Uri.encodeComponent(customerId)}',
  );
  return OutstandingInvoice.fromResponse(response.data);
}
