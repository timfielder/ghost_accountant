import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import '../../models/entity_model.dart';

class SplitRowData {
  String id;
  String entityId;
  double percent; // 0.0 to 1.0
  String? category;
  TextEditingController amountController;
  TextEditingController percentController;

  // NEW: Validation State
  bool hasError;

  SplitRowData({
    required this.id,
    required this.entityId,
    this.percent = 0.0,
    this.category,
    required double totalDollars,
    this.hasError = false,
  }) :
        amountController = TextEditingController(text: (totalDollars * percent).toStringAsFixed(2)),
        percentController = TextEditingController(text: (percent * 100).toStringAsFixed(0));
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
    _initializeSplit();
  }

  void _initializeSplit() {
    final provider = context.read<TransactionProvider>();
    final double totalDollars = (widget.transaction['amount_cents'] as int) / 100.0;

    // 1. ANCHOR (Row 0): The Primary LLC. Starts at 100%.
    final primary = provider.entities.firstWhere((e) => e.isPrimary, orElse: () => provider.entities.first);
    rows.add(SplitRowData(id: uuid.v4(), entityId: primary.id, percent: 1.0, category: null, totalDollars: totalDollars));

    // 2. THIEF (Row 1): The Secondary Stream. Starts at 0%.
    final secondary = provider.entities.firstWhere((e) => e.id != primary.id, orElse: () => provider.entities.last);
    if (secondary.id != primary.id) {
      rows.add(SplitRowData(id: uuid.v4(), entityId: secondary.id, percent: 0.0, category: null, totalDollars: totalDollars));
    }
  }

  void _addSplitRow() {
    final provider = context.read<TransactionProvider>();
    final double totalDollars = (widget.transaction['amount_cents'] as int) / 100.0;

    final usedIds = rows.map((r) => r.entityId).toSet();
    final nextEntity = provider.entities.firstWhere((e) => !usedIds.contains(e.id), orElse: () => provider.entities.first);

    setState(() {
      rows.add(SplitRowData(id: uuid.v4(), entityId: nextEntity.id, percent: 0.0, category: null, totalDollars: totalDollars));
    });
  }

  void _removeRow(int index) {
    if (index == 0) return; // Cannot delete Anchor
    setState(() {
      rows.removeAt(index);
      _recalculateAnchor();
    });
  }

  // --- FLUID LOGIC ENGINE ---
  void _updateRow(int activeIndex, double desiredPercent) {
    if (activeIndex == 0) return; // Anchor moves automatically

    setState(() {
      double otherThievesTotal = 0.0;
      for (int i = 1; i < rows.length; i++) {
        if (i != activeIndex) otherThievesTotal += rows[i].percent;
      }

      double maxAvailable = 1.0 - otherThievesTotal;
      double actualPercent = desiredPercent.clamp(0.0, maxAvailable);

      rows[activeIndex].percent = actualPercent;
      _recalculateAnchor();
    });
  }

  void _recalculateAnchor() {
    double thievesTotal = 0.0;
    for (int i = 1; i < rows.length; i++) {
      thievesTotal += rows[i].percent;
    }

    double anchorPercent = (1.0 - thievesTotal).clamp(0.0, 1.0);
    rows[0].percent = anchorPercent;

    _syncControllers();
  }

  void _syncControllers() {
    final double totalDollars = (widget.transaction['amount_cents'] as int) / 100.0;

    for (var row in rows) {
      row.percentController.text = (row.percent * 100).toStringAsFixed(0);
      row.amountController.text = (totalDollars * row.percent).toStringAsFixed(2);
    }
  }

  Future<void> _submit() async {
    final provider = context.read<TransactionProvider>();
    final txId = widget.transaction['transaction_id'];
    List<Map<String, dynamic>> finalSplits = [];
    bool hasValidationError = false;

    // RESET ERRORS
    setState(() {
      for (var row in rows) row.hasError = false;
    });

    // VALIDATION LOOP
    for (var row in rows) {
      double dollarAmount = double.tryParse(row.amountController.text) ?? 0.0;
      int amountCents = (dollarAmount * 100).round();

      // LOGIC: Only validate rows with actual money allocated (> $0.00)
      if (amountCents > 0) {
        // If category is missing, FLAG IT
        if (row.category == null || row.category == 'Uncategorized') {
          setState(() => row.hasError = true); // Triggers Red Border
          hasValidationError = true;
        } else {
          finalSplits.add({
            'entityId': row.entityId,
            'amount': amountCents,
            'category': row.category
          });
        }
      }
    }

    if (hasValidationError) {
      // UX: Quick vibration or snackbar to say "Check highlighted fields"
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a category for the highlighted streams."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          )
      );
      return;
    }

    if (finalSplits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Total allocation cannot be zero."))
      );
      return;
    }

    await provider.finalizeSplit(transactionId: txId, splitRows: finalSplits);

    if (mounted) {
      Navigator.pop(context);
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final entities = provider.entities;
    final int totalCents = widget.transaction['amount_cents'] as int;
    final double amount = totalCents / 100.0;

    // COMPASS PALETTE
    final sjNavy = Theme.of(context).colorScheme.secondary; // Foundation
    final sjTeal = Theme.of(context).colorScheme.primary;   // Streams
    final sjGold = Theme.of(context).colorScheme.tertiary;  // Value

    final accountName = widget.transaction['institution_name'] ?? 'Unknown Acct';

    // 1. FILTER CATEGORIES (Credit vs Debit)
    final bool isCredit = totalCents < 0;
    final List<Map<String, dynamic>> categoryList = isCredit
        ? AppConstants.creditCategories
        : AppConstants.debitCategories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(width: 40, height: 4, color: Colors.black12),
            const SizedBox(height: 24),

            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("WATERFALL SPLIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(widget.transaction['merchant_name'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: sjNavy)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(widget.transaction['date'].toString().substring(0, 10), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.circle, size: 4, color: Colors.grey.shade300)),
                          Icon(Icons.credit_card, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(child: Text(accountName, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  "\$${amount.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isCredit ? sjTeal : sjNavy,
                      letterSpacing: -1.0
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),

            // --- THE LIST ---
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final isAnchor = index == 0;
                  final isZero = row.percent == 0.0;

                  // Visual Colors
                  final Color rowColor = isAnchor ? sjNavy : sjTeal;
                  final Color bgColor = isAnchor ? sjNavy.withOpacity(0.05) : Colors.white;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                          color: isZero ? Colors.grey.shade200 : rowColor.withOpacity(0.5)
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isZero ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        // ROW 1: Entity Name & Amount
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: isAnchor
                              // Anchor Name is Fixed
                                  ? Row(children: [
                                Icon(Icons.shield, size: 16, color: sjNavy),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                    provider.entities.firstWhere((e) => e.id == row.entityId).name,
                                    style: TextStyle(color: sjNavy, fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis
                                ))
                              ])
                              // Stream Name is Selectable
                                  : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: row.entityId,
                                  isDense: true,
                                  isExpanded: true,
                                  icon: Icon(Icons.expand_more, color: sjTeal),
                                  items: entities.map((e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(e.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: sjTeal), overflow: TextOverflow.ellipsis),
                                  )).toList(),
                                  onChanged: (val) => setState(() => row.entityId = val!),
                                ),
                              ),
                            ),

                            // Amount Display
                            Text(
                              "\$${row.amountController.text}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rowColor,
                                  fontSize: 16
                              ),
                            ),

                            if (!isAnchor)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.black38),
                                onPressed: () => _removeRow(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            else
                              const SizedBox(width: 24)
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ROW 2: Slider & Percent
                        Row(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 36,
                              child: TextField(
                                controller: row.percentController,
                                enabled: false,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: rowColor),
                                decoration: InputDecoration(
                                    suffixText: "%",
                                    suffixStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                                    contentPadding: const EdgeInsets.only(bottom: 12),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300))
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  activeTrackColor: rowColor,
                                  thumbColor: rowColor,
                                  inactiveTrackColor: Colors.grey.shade200,
                                ),
                                child: Slider(
                                  value: row.percent,
                                  min: 0.0, max: 1.0,
                                  onChanged: isAnchor ? null : (val) => _updateRow(index, val),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ROW 3: Category (Fade out if $0.00)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isZero ? 0.0 : 1.0,
                          child: isZero ? const SizedBox.shrink() : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  // HIGHLIGHT LOGIC: Red Border if Error, Grey if Normal
                                  border: Border.all(
                                      color: row.hasError ? Colors.red : Colors.grey.shade300,
                                      width: row.hasError ? 1.5 : 1.0
                                  ),
                                  borderRadius: BorderRadius.circular(6)
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: row.category == 'Uncategorized' ? null : row.category,
                                  hint: Text(
                                      row.hasError ? "Required Field" : "Select Category",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: row.hasError ? Colors.red : Colors.grey,
                                          fontWeight: row.hasError ? FontWeight.bold : FontWeight.normal
                                      )
                                  ),
                                  isExpanded: true,
                                  icon: Icon(Icons.expand_more, size: 18, color: row.hasError ? Colors.red : Colors.black54),
                                  // FILTERED LIST: Uses categoryList defined at build start
                                  items: categoryList.map<DropdownMenuItem<String>>((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat['name'] as String,
                                      child: Row(
                                        children: [
                                          Icon(cat['icon'], size: 14, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(cat['name'] as String, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() {
                                    row.category = val!;
                                    row.hasError = false; // Clear error on interaction
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            TextButton.icon(
              onPressed: _addSplitRow,
              icon: Icon(Icons.add_circle, color: sjTeal),
              label: Text("Add Split Line", style: TextStyle(color: sjTeal, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // BUTTON IS ALWAYS ACTIVE
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: sjTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text(
                    "CONFIRM SPLIT",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}