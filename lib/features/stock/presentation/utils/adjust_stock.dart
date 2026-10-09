import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/widgets/app_snackbar.dart';

Future<bool> adjustStock(BuildContext context, String itemId) async {
  final api = ApiClient(baseUrl);
  try {
    final response = await api.get(InventoryEndpoints.byId(itemId));
    final item = Map<String, dynamic>.from(response.data['data'] as Map);
    final variants = (item['variants'] as List? ?? [])
        .whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
    if (!context.mounted) return false;
    int selected = 0;
    bool saving = false;
    String? error;
    final delta = TextEditingController(text: '1');
    bool add = true;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final current = variants.isEmpty ? item : variants[selected];
          return AlertDialog(
            title: Text('Adjust stock · ${item['itemName'] ?? 'Product'}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (variants.isNotEmpty)
                  DropdownButton<int>(
                    value: selected,
                    isExpanded: true,
                    items: [
                      for (var i = 0; i < variants.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${variants[i]['color'] ?? ''} ${variants[i]['storage'] ?? ''} · ${variants[i]['quantity'] ?? 0} in stock',
                          ),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) => update(() => selected = value ?? selected),
                  ),
                Text('Current stock: ${current['quantity'] ?? 0}'),
                Row(
                  children: [
                    TextButton(
                      onPressed: saving ? null : () => update(() => add = true),
                      child: Text(add ? '+ Add ✓' : '+ Add'),
                    ),
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => update(() => add = false),
                      child: Text(!add ? '− Remove ✓' : '− Remove'),
                    ),
                  ],
                ),
                TextField(
                  controller: delta,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final amount = int.tryParse(delta.text);
                        final original =
                            (current['quantity'] as num?)?.toInt() ?? 0;
                        if (amount == null ||
                            amount <= 0 ||
                            amount > 9999 ||
                            (!add && amount > original)) {
                          update(
                            () => error =
                                'Enter a valid quantity without making stock negative',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          // Re-read before updating, so an adjustment does not use a stale
                          // quantity from a list that was loaded earlier.
                          final latest = await api.get(
                            InventoryEndpoints.byId(itemId),
                          );
                          final raw = latest.data['data'] as Map;
                          final latestVariants =
                              (raw['variants'] as List? ?? [])
                                  .whereType<Map>()
                                  .map((v) => Map<String, dynamic>.from(v))
                                  .toList();
                          final index = variants.isEmpty
                              ? -1
                              : latestVariants.indexWhere(
                                  (v) => v['_id'] == current['_id'],
                                );
                          if (variants.isNotEmpty && index < 0) {
                            throw const FormatException(
                              'Variation changed. Reopen stock adjustment.',
                            );
                          }
                          final latestQty =
                              ((index < 0
                                          ? raw
                                          : latestVariants[index])['quantity']
                                      as num?)
                                  ?.toInt() ??
                              0;
                          if (latestQty != original) {
                            throw const FormatException(
                              'Stock changed. Reopen stock adjustment.',
                            );
                          }
                          final next = original + (add ? amount : -amount);
                          final updateData = <String, dynamic>{};
                          if (index < 0) {
                            updateData['quantity'] = next;
                          } else {
                            latestVariants[index]['quantity'] = next;
                            updateData['variants'] = latestVariants;
                          }
                          await api.put(
                            InventoryEndpoints.byId(itemId),
                            data: updateData,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            update(() {
                              saving = false;
                              error = e is FormatException
                                  ? e.message
                                  : 'Could not save stock. Refresh and try again.';
                            });
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
    delta.dispose();
    if (saved == true) showSuccessSnackbar('Stock quantity updated');
    return saved == true;
  } catch (_) {
    showErrorSnackbar('Could not load current stock');
    return false;
  }
}
