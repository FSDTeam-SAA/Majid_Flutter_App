import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/colors.dart';

class LocalInvoicePdfPage extends StatelessWidget {
  const LocalInvoicePdfPage({
    super.key,
    required this.file,
    this.title = 'Invoice',
  });

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.cardBackground,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(title),
    ),
    body: SafeArea(
      child: PdfPreview(
        build: (_) => file.readAsBytes(),
        pdfFileName: file.uri.pathSegments.last,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        dynamicLayout: false,
        scrollViewDecoration: BoxDecoration(color: AppColors.background),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        actionBarTheme: const PdfActionBarTheme(elevation: 0),
        onError: (context, error) => Center(
          child: Text(
            'Could not display this PDF.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    ),
  );
}
