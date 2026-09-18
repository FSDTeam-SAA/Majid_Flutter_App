import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/calculation_line.dart';
import '../../domain/entities/ready_order.dart';
import '../utils/amount_expression.dart';

/// The sale being built on the Checkout screen: keypad amounts, the names and
/// note given to them, and any repairs pulled in for collection.
///
/// This lives outside the page because the bottom navigation rebuilds its
/// pages, so anything kept in `StockPage`'s State is thrown away the moment
/// the shopkeeper looks at another tab. It is also written to disk, since a
/// half-rung-up sale should survive the app being closed — there is no backend
/// endpoint for an unfinished checkout (`/add-to-cart` only takes inventory
/// item ids, not hand-keyed amounts).
///
/// Stock items are held by [StockBasketController]; this covers everything
/// else on the screen.
class CheckoutDraftController extends GetxController {
  static const _storageKey = 'stock_checkout_draft';

  static CheckoutDraftController get instance {
    if (!Get.isRegistered<CheckoutDraftController>()) {
      Get.put(CheckoutDraftController(), permanent: true);
    }
    return Get.find<CheckoutDraftController>();
  }

  AmountExpression expression = AmountExpression.empty;

  /// Repairs pulled into the sale, keyed by order id and kept in the order
  /// they were added.
  final Map<String, ReadyOrder> repairs = {};

  /// Names given to calculated lines on the Calculation Note screen, keyed by
  /// the term as typed.
  final Map<String, String> lineNames = {};

  String note = '';

  /// Bumped on every change, including the restore from disk, so widgets can
  /// rebuild through a plain `Obx`.
  final revision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  /// One row per pulled-in repair, in the order they were added.
  List<CalculationLine> get repairLines => [
    for (final order in repairs.values)
      CalculationLine(
        expression: '1',
        quantity: 1,
        amount: order.price,
        name: '${order.deviceModel} repair',
      ),
  ];

  /// Keypad terms carrying any name the shopkeeper has given them.
  List<CalculationLine> get namedLines => [
    for (final line in expression.lines)
      line.copyWith(name: lineNames[line.expression] ?? ''),
  ];

  /// Repairs first, then keypad terms — the order the review screen lists
  /// them in, and the order its removal callback indexes.
  List<CalculationLine> get combinedLines => [...repairLines, ...namedLines];

  int get totalQuantity => repairs.length + expression.totalQuantity;

  bool get isEmpty => expression.isEmpty && repairs.isEmpty;

  void setExpression(AmountExpression next) {
    expression = next;
    _changed();
  }

  void addRepair(ReadyOrder order) {
    repairs[order.id] = order;
    _changed();
  }

  void setLineNames(Map<String, String> names) {
    lineNames
      ..clear()
      ..addAll(names);
    _changed();
  }

  void setNote(String value) {
    note = value;
    _changed();
  }

  /// Removes one row of [combinedLines]: repairs come first, keypad terms
  /// after them.
  void removeLineAt(int index) {
    if (index < repairs.length) {
      repairs.remove(repairs.keys.elementAt(index));
    } else {
      expression = expression.removeTermAt(index - repairs.length);
    }
    _changed();
  }

  /// Empties the keypad and repairs. The stock basket is cleared separately.
  void clear() {
    expression = AmountExpression.empty;
    repairs.clear();
    lineNames.clear();
    note = '';
    _changed();
  }

  void _changed() {
    revision.value++;
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isEmpty && note.isEmpty) {
        await prefs.remove(_storageKey);
        return;
      }
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'expression': expression.input,
          'note': note,
          'names': lineNames,
          'repairs': [for (final order in repairs.values) order.toJson()],
        }),
      );
    } catch (_) {
      // A draft that cannot be written is not worth interrupting a sale for;
      // it simply falls back to living in memory for this run.
    }
  }

  /// Reads back the last saved draft. Failures leave the checkout empty
  /// rather than blocking it.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw);
      if (data is! Map) return;

      expression = AmountExpression.restore(
        data['expression']?.toString() ?? '',
      );
      note = data['note']?.toString() ?? '';

      lineNames
        ..clear()
        ..addEntries(
          (data['names'] as Map? ?? {}).entries.map(
            (entry) => MapEntry(entry.key.toString(), entry.value.toString()),
          ),
        );

      repairs.clear();
      for (final item in (data['repairs'] as List? ?? [])) {
        if (item is! Map) continue;
        final order = ReadyOrder.fromJson(Map<String, dynamic>.from(item));
        if (order.id.isNotEmpty) repairs[order.id] = order;
      }

      revision.value++;
    } catch (_) {
      // Corrupt or outdated draft: start clean.
    }
  }
}
