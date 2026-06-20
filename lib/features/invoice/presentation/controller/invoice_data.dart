import 'package:flutter/material.dart';

class InvoiceProduct {
  final String name;
  final String code;
  final double price;
  final Color color;
  const InvoiceProduct({
    required this.name,
    required this.code,
    required this.price,
    required this.color,
  });
}

const List<InvoiceProduct> invoiceProducts = [
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFFD4A853),
  ),
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFF2C2C2E),
  ),
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFF5B8DEF),
  ),
  InvoiceProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    color: Color(0xFFE75480),
  ),
];

const List<String> customers = ['Muhammad Majid', 'Sarah Johnson', 'David Lee'];
const List<String> paymentTypes = ['Cash', 'Card', 'Bank Transfer', 'Online'];
