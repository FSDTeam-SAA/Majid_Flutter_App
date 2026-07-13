import 'dart:io';

import 'package:dio/dio.dart' show FormData;

import '../../presentation/controller/invoice_data.dart';
import '../entities/invoice.dart';

/// Thrown by [InvoiceRepository.extractNid] when the OCR call fails or does
/// not return a usable NID number. The [message] mirrors the text
/// previously shown directly in the UI's SnackBars.
class InvoiceException implements Exception {
  final String message;

  const InvoiceException(this.message);

  @override
  String toString() => message;
}

abstract class InvoiceRepository {
  /// Creates an invoice (sales, purchase, or delivery) from a pre-built
  /// multipart [payload] (fields + generated PDF file). The three invoice
  /// flows differ only in the fields/PDF they build, so they all funnel
  /// through this single method.
  Future<void> createInvoice(FormData payload);

  /// Fetches the invoice history for a shopkeeper.
  Future<List<Invoice>> getInvoices(String shopkeeperId);

  /// Fetches the shopkeeper's inventory items for use as invoice line
  /// items. This intentionally lives on [InvoiceRepository] rather than a
  /// dedicated stock feature repository, since the stock feature does not
  /// yet have a data/domain layer of its own.
  Future<List<InvoiceProduct>> getInventoryItems();

  /// Extracts an NID number from the given front/back images.
  ///
  /// Throws an [InvoiceException] when the OCR call fails or does not
  /// return a usable NID number.
  Future<String> extractNid({File? frontImage, File? backImage});
}
