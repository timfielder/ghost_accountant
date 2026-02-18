import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import '../../models/entity_model.dart'; // FIXED IMPORT PATH

class SplitRowData {
  String id;
  String entityId;
  double percent;
  String category;
  TextEditingController amountController;

  SplitRowData({
    required this.id,
    required this.entityId,
    this.percent = 0.0,
    this.category = 'Uncategorized',
    required String initialAmount
  }) : amountController = TextEditingController(text: initialAmount);
}

class TriageBottomSheet extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(bool) onComplete;

  const TriageBottomSheet({super.key, required this.transaction, required this.onComplete});

  @override
  State<TriageBottomSheet> createState() => _TriageBottomSheetState();
}

class _TriageBottomSheetState extends State<TriageBottomSheet> {
  List<SplitRowData> rows = [];
  final Uuid uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    final totalCents = widget.transaction['amount_cents'];
    final double totalDollars = totalCents / 100.0;

    if (provider.entities.isNotEmpty) {
      // Default to Primary Entity or first available
      final primary = provider.entities.firstWhere((e) => e.isPrimary, orElse: () => provider.entities.first);

      rows.add(SplitRowData(
          id: uuid.v4(),
          entityId: primary.id,
          percent: 1.0,
          category: 'Uncategorized',
          initialAmount: totalDollars.toStringAsFixed(2)
      ));
    }
  }

  void _addSplitRow() {
    setState(() {
      final provider = context.read<TransactionProvider>();
      final primary = provider.entities.firstWhere((e) => e.isPrimary, orElse: () => provider.entities.first);

      rows.add(SplitRowData(
          id: uuid.v4(),
          entityId: primary.id,
          percent: 0.0,
          category: 'Uncategorized',
          initialAmount: "0.00"
      ));
    });
  }

  void _removeRow(int index) {
    if (rows.length > 1) {
      setState(() {
        rows.removeAt(index);
      });
    }
  }

  void _updateRow(String activeRowId, double? sliderValue, String? textValue) {
    final totalCents = widget.transaction['amount_cents'];
    double totalDollars = totalCents / 100.0;

    // AUTO-SPAWN CHECK: If user touches the slider and there is only 1 row, automatically add the second row
    if (rows.length == 1) {
      final provider = context.read<TransactionProvider>();
      final currentEntityId = rows.first.entityId;
      // Try to find a different entity to suggest
      final nextEntity = provider.entities.firstWhere((e) => e.id != currentEntityId, orElse: () => provider.entities.first);

      if (nextEntity.id != currentEntityId) {
        setState(() {
          rows.add(SplitRowData(
              id: uuid.v4(),
              entityId: nextEntity.id,
              percent: 0.0,
              category: 'Uncategorized',
              initialAmount: "0.00"
          ));
        });
      }
    }

    setState(() {
      double newPercent = 0.0;

      if (sliderValue != null) newPercent = sliderValue;
      if (textValue != null) {
        double amount = double.tryParse(textValue) ?? 0.0;
        newPercent = amount / totalDollars;
      }

      if (newPercent > 1.0) newPercent = 1.0;
      if (newPercent < 0.0) newPercent = 0.0;

      final activeRow = rows.firstWhere((r) => r.id == activeRowId);
      activeRow.percent = newPercent;

      // Update text if slider moved
      if (sliderValue != null) {
        activeRow.amountController.text = (totalDollars * newPercent).toStringAsFixed(2);
      }

      // WATERFALL LOGIC: Adjust the *other* rows to equal 100%
      // Simplified Waterfall for 2 items: 1 - newPercent
      double remainder = 1.0 - newPercent;

      for (var row in rows) {
        if (row.id != activeRowId) {
          row.percent = remainder < 0 ? 0 : remainder;
          row.amountController.text = (totalDollars * row.percent).toStringAsFixed(2);
          remainder = 0; // Only fill the first available bucket for now (MVP)
          break;
        }
      }
    });
  }

  Future<void> _submit() async {
    final provider = context.read<TransactionProvider>();
    final txId = widget.transaction['transaction_id'];

    List<Map<String, dynamic>> finalSplits = [];

    for (var row in rows) {
      double dollarAmount = double.tryParse(row.amountController.text) ?? 0.0;
      if (dollarAmount > 0) {
        finalSplits.add({
          'entityId': row.entityId,
          'amount': (dollarAmount * 100).round(),
          'category': row.category
        });
      }
    }

    await provider.finalizeSplit(
      transactionId: txId,
      splitRows: finalSplits,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entities = context.watch<TransactionProvider>().entities;
    final totalCents = widget.transaction['amount_cents'];

    // BRAND COLOR
    final tfeGreen = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, color: Colors.black12),
          const SizedBox(height: 20),
          Text(widget.transaction['merchant_name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("\$${(totalCents / 100).toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, color: Colors.black54)),
          const Divider(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12), // Crisp Border
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: row.entityId,
                                isDense: true,
                                isExpanded: true,
                                items: entities.map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis
                                  ),
                                )).toList(),
                                onChanged: (val) => setState(() => row.entityId = val!),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: row.amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                prefixText: "\$",
                                border: OutlineInputBorder(), // Uses Theme Defaults (Green Focus)
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                              onChanged: (val) => _updateRow(row.id, null, val),
                            ),
                          ),
                          if (rows.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                              onPressed: () => _removeRow(index),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: row.percent,
                              min: 0.0, max: 1.0,
                              activeColor: tfeGreen, // FORCE BRAND GREEN
                              thumbColor: tfeGreen,
                              onChanged: (val) => _updateRow(row.id, val, null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: row.category == 'Uncategorized' ? null : row.category,
                                  hint: const Text("Category", style: TextStyle(fontSize: 12)),
                                  isExpanded: true,
                                  // Use the static getter we created in AppConstants
                                  items: AppConstants.allCategories.map<DropdownMenuItem<String>>((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat['name'] as String,
                                      child: Row(
                                        children: [
                                          Icon(cat['icon'], size: 16, color: tfeGreen), // GREEN ICONS
                                          const SizedBox(width: 5),
                                          Expanded(
                                              child: Text(
                                                  cat['name'] as String,
                                                  style: const TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis
                                              )
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => row.category = val!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          TextButton.icon(
            onPressed: _addSplitRow,
            icon: Icon(Icons.add_circle, color: tfeGreen), // GREEN ICON
            label: Text("Add Split Line", style: TextStyle(color: tfeGreen)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: tfeGreen, // FORCE BRAND GREEN
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("CONFIRM SPLIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}