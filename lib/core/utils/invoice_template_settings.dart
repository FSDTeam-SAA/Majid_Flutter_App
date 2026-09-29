import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InvoiceCategory { modern, traditional }

class InvoiceTemplateItem {
  final String id;
  final String name;
  final InvoiceCategory category;
  final String description;
  final bool isDefault;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color headerColor;
  final String badge;
  final List<String> features;

  const InvoiceTemplateItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.isDefault = false,
    required this.primaryColor,
    required this.accentColor,
    this.backgroundColor = Colors.white,
    this.headerColor = Colors.white,
    required this.badge,
    required this.features,
  });

  String get categoryName =>
      category == InvoiceCategory.traditional ? 'Traditional' : 'Modern';
}

/// Global settings and persistence for the active invoice template design.
class InvoiceTemplateSettings {
  static const String _key = 'preferred_invoice_template';

  static const List<InvoiceTemplateItem> templates = [
    InvoiceTemplateItem(
      id: 'default',
      name: 'Default (Classic Teal)',
      category: InvoiceCategory.modern,
      description:
          'Original teal & emerald styling with balanced metadata grid, device info column, and clean total band.',
      isDefault: true,
      primaryColor: Color(0xFF155E63),
      accentColor: Color(0xFF84CC16),
      backgroundColor: Colors.white,
      headerColor: Color(0xFFF8FAFC),
      badge: 'Current Default',
      features: [
        'Teal & lime accents',
        'Standard store & client pills',
        'Dual payment status badge',
      ],
    ),
    InvoiceTemplateItem(
      id: 'classic-editorial',
      name: 'Classic Editorial',
      category: InvoiceCategory.traditional,
      description:
          'Refined serif typography, rich burgundy headers, formal divider rules, and editorial billing structure.',
      primaryColor: Color(0xFF800020),
      accentColor: Color(0xFF991B1B),
      backgroundColor: Colors.white,
      headerColor: Colors.white,
      badge: 'Reference 1',
      features: [
        'Classic serif font layout',
        'Rich burgundy accents',
        'Paid badge & barcode strip',
        'Formal horizontal rules',
      ],
    ),
    InvoiceTemplateItem(
      id: 'warm-minimal',
      name: 'Warm Minimalist',
      category: InvoiceCategory.traditional,
      description:
          'Warm parchment background, fine outer framing border, centered traditional letterhead, and underline items.',
      primaryColor: Color(0xFF1C1917),
      accentColor: Color(0xFF84CC16),
      backgroundColor: Color(0xFFFFFDEB),
      headerColor: Color(0xFFFFFDEB),
      badge: 'Reference 4',
      features: [
        'Warm parchment paper tone',
        'Thin framing border',
        'Centered brand letterhead',
        'Lime pill total highlight',
      ],
    ),
    InvoiceTemplateItem(
      id: 'neo-bold',
      name: 'Neo Bold',
      category: InvoiceCategory.modern,
      description:
          'High-contrast neo-brutalist styling with electric lime banners, rounded cards, and bold grotesque type.',
      primaryColor: Color(0xFF0F172A),
      accentColor: Color(0xFFD4FF32),
      backgroundColor: Color(0xFFFDF4F5),
      headerColor: Color(0xFFD4FF32),
      badge: 'Reference 2',
      features: [
        'Electric lime banners',
        'Heavy grotesque bold fonts',
        'Segmented card layout',
        'Vibrant total amount block',
      ],
    ),
    InvoiceTemplateItem(
      id: 'modern-retail',
      name: 'Modern Retail',
      category: InvoiceCategory.modern,
      description:
          'Contemporary retail invoice with calming sage green table header, checkmark paid badge, and phone buyback promo.',
      primaryColor: Color(0xFF2D3748),
      accentColor: Color(0xFF8EA085),
      backgroundColor: Colors.white,
      headerColor: Color(0xFF8EA085),
      badge: 'Reference 3',
      features: [
        'Sage green table banner',
        'Clean sans-serif typography',
        'Checkmark paid pill',
        'Buyback trade-in footer',
      ],
    ),
    InvoiceTemplateItem(
      id: 'nordic-modern',
      name: 'Nordic Slate',
      category: InvoiceCategory.modern,
      description:
          'Spacious Scandinavian design with extra-large typography, prominent total highlight box, and cool slate tones.',
      primaryColor: Color(0xFF0F172A),
      accentColor: Color(0xFF84CC16),
      backgroundColor: Colors.white,
      headerColor: Color(0xFFF1F5F9),
      badge: 'Reference 5',
      features: [
        'Large bold INVOICE title',
        'Customer pill badge',
        'Top-level prominent total box',
        'Cool slate gray header',
      ],
    ),
  ];

  /// Live notifier holding the currently active template ID.
  static final ValueNotifier<String> currentTemplate =
      ValueNotifier<String>('default');

  /// Loads the saved template from local storage, defaulting to 'default'.
  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'default';
    currentTemplate.value = saved;
    return saved;
  }

  /// Saves the preferred template to local storage and updates the notifier.
  static Future<void> save(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, templateId);
    currentTemplate.value = templateId;
  }

  /// Returns the [InvoiceTemplateItem] corresponding to [id], or the default.
  static InvoiceTemplateItem getTemplate([String? id]) {
    final target = id ?? currentTemplate.value;
    return templates.firstWhere(
      (t) => t.id == target,
      orElse: () => templates.first,
    );
  }
}
