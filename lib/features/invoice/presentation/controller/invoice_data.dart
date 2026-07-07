import 'package:flutter/material.dart';

class InvoiceProduct {
  final String id;
  final String name;
  final String code;
  final String imeiSerial;
  final double price;
  final Color color;
  final String category;
  InvoiceProduct({
    this.id = '',
    required this.name,
    required this.code,
    this.imeiSerial = '',
    required this.price,
    required this.color,
    this.category = '',
  });
}

List<InvoiceProduct> invoiceProducts = [
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFFD4A853),
    category: 'Phones',
  ),
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFF2C2C2E),
    category: 'Phones',
  ),
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFF5B8DEF),
    category: 'Phones',
  ),
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFFE75480),
    category: 'Phones',
  ),
];

List<String> customers = ['Muhammad Majid', 'Sarah Johnson', 'David Lee'];
List<String> paymentTypes = ['Cash', 'Card', 'Bank Transfer', 'Online'];
