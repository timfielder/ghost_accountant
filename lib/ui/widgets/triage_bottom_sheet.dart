import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import '../../models/entity_model.dart';

class SplitRowData {
  String id;
  String? entityId; // Nullable to allow "Select a Stream" state
  double percent;
  String? category;
  TextEditingController amountController;
  TextEditingController percentController;
  TextEditingController memoController;
  bool hasError;

  SplitRowData({
    required this.id,
    this.entityId, // Optional
    this.percent = 0.0,
    this.category,
    required double totalDollars,
    this.hasError = false,
  }) :
        amountController = TextEditingController(text: (totalDollars * percent).toStringAsFixed(2)),
        percentController = TextEditingController(text: (percent * 100).toStringAsFixed(0)),
        memoController = TextEditingController();
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
    _initializeState();
  }

  void _initializeState() {
    final provider = context.read<TransactionProvider>();
    final double totalDollars = (widget.transaction['amount_cents'] as int) / 100.0;

    // Anchor Row (Index 0): Must have a valid entity (Primary)
    final primary = provider.entities.firstWhere((e) => e.isPrimary, orElse: () => provider.entities.first);
    rows.add(SplitRowData(id: uuid.v4(), entityId: primary.id, percent: 1.0, category: null, totalDollars: totalDollars));

    // Second Row: Starts Blank (Null Entity) to force explicit selection
    rows.add(SplitRowData(id: uuid.v4(), entityId: null, percent: 0.0, category: null, totalDollars: totalDollars));
  }

  void _addSplitRow() {
    final double totalDollars = (widget.transaction['amount_cents'] as int) / 100.0;

    setState(() {
      rows.add(SplitRowData(id: uuid.v4(), entityId: null, percent: 0.0, category: null, totalDollars: totalDollars));
    });
  }

  void _removeRow(int index) {
    if (index == 0) return; // Cannot remove Anchor
    setState(() {
      rows.removeAt(index);
      _recalculateAnchor(); // Logic automatically returns money to the Umbrella/Anchor
    });
  }

  void _updateRow(int activeIndex, double desiredPercent) {
    if (activeIndex == 0) return; // Anchor is calculated, not driven

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
    rows.first.percent = anchorPercent;
    _syncControllers();
  }

  void _syncControllers() {
    final double totalDollars = (widget.transaction['amount_cents'] as int) / 100.0;
    for (var row in rows) {
      row.percentController.text = (row.percent * 100).toStringAsFixed(0);
      row.amountController.text = (totalDollars * row.percent).toStringAsFixed(2);
    }
  }

  // --- STREAM PICKER ---
  void _openStreamPicker(int rowIndex, List<Entity> entities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Select Stream", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: entities.length,
                itemBuilder: (ctx, index) {
                  final e = entities[index];
                  final bool isSelected = rows[rowIndex].entityId == e.id;

                  return ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(e.isPrimary ? Icons.security : Icons.layers, color: Theme.of(context).colorScheme.primary, size: 20)
                    ),
                    title: Text(e.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                    subtitle: Text(e.isPrimary ? "Organization" : "Business Stream", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () {
                      setState(() {
                        rows[rowIndex].entityId = e.id;
                        rows[rowIndex].hasError = false;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CATEGORY PICKER ---
  void _openCategoryPicker(int rowIndex, List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Select Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final bool isSelected = rows[rowIndex].category == cat['name'];

                  return ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(cat['icon'], color: Theme.of(context).colorScheme.primary, size: 20)
                    ),
                    title: Text(cat['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                    subtitle: Text(cat['desc'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () {
                      setState(() {
                        rows[rowIndex].category = cat['name'];
                        rows[rowIndex].hasError = false;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<TransactionProvider>();
    final txId = widget.transaction['transaction_id'];

    List<Map<String, dynamic>> finalSplits = [];
    bool hasValidationError = false;

    setState(() {
      for (var row in rows) row.hasError = false;
    });

    for (var row in rows) {
      double dollarAmount = double.tryParse(row.amountController.text) ?? 0.0;
      int amountCents = (dollarAmount * 100).round();

      if (amountCents > 0) {
        // Validation: Must select Entity AND Category for lines with money
        if (row.entityId == null || row.category == null || row.category == 'Uncategorized') {
          setState(() => row.hasError = true);
          hasValidationError = true;
        } else {
          finalSplits.add({
            'entityId': row.entityId,
            'amount': amountCents,
            'category': row.category,
            'memo': row.memoController.text
          });
        }
      }
    }

    if (hasValidationError) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a Stream and Category for all active lines."), backgroundColor: Colors.red, duration: Duration(seconds: 2))
      );
      return;
    }

    if (finalSplits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Total allocation cannot be zero.")));
      return;
    }

    await provider.finalizeSplit(
        transactionId: txId,
        splitRows: finalSplits,
        note: null
    );

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

    final sjNavy = Theme.of(context).colorScheme.secondary;
    final sjTeal = Theme.of(context).colorScheme.primary;
    final accountName = widget.transaction['institution_name'] ?? 'Unknown Acct';

    final bool isCredit = totalCents < 0;
    final List<Map<String, dynamic>> categoryList = isCredit ? AppConstants.creditCategories : AppConstants.debitCategories;

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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isCredit ? sjTeal : sjNavy, letterSpacing: -1.0),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),

            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final isAnchor = index == 0;
                  final isZero = row.percent == 0.0;
                  final Color rowColor = isAnchor ? sjNavy : sjTeal;
                  final Color bgColor = isAnchor ? sjNavy.withOpacity(0.05) : Colors.white;

                  String streamDisplay = "Select a Stream";
                  if (row.entityId != null) {
                    try {
                      streamDisplay = provider.entities.firstWhere((e) => e.id == row.entityId).name;
                    } catch (_) {}
                  }

                  // ERROR STATE LOGIC
                  // If row.hasError is TRUE, we check which field is missing.
                  final bool isStreamError = row.hasError && row.entityId == null;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: isZero ? Colors.grey.shade200 : rowColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isZero ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: isAnchor
                                  ? Row(children: [
                                Icon(Icons.shield, size: 16, color: sjNavy),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                    streamDisplay,
                                    style: TextStyle(color: sjNavy, fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis
                                ))
                              ])
                                  : InkWell(
                                onTap: () => _openStreamPicker(index, entities),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: isStreamError ? Colors.red : Colors.grey.shade300,
                                          width: isStreamError ? 1.5 : 1.0
                                      ),
                                      borderRadius: BorderRadius.circular(6)
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            streamDisplay,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: isStreamError ? Colors.red : sjTeal
                                            ),
                                            overflow: TextOverflow.ellipsis
                                        ),
                                      ),
                                      Icon(Icons.expand_more, size: 18, color: isStreamError ? Colors.red : sjTeal)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "\$${row.amountController.text}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: rowColor, fontSize: 16),
                            ),
                            if (!isAnchor)
                              IconButton(
                                // UPDATED: Trash Can Icon for deleting rows
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => _removeRow(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            else
                              const SizedBox(width: 24)
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            SizedBox(
                              width: 50, height: 36,
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

                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: InkWell(
                                onTap: () => _openCategoryPicker(index, categoryList),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      // Specific Border Error for Category Field
                                      border: Border.all(
                                          color: row.hasError && row.category == null ? Colors.red : Colors.grey.shade300,
                                          width: row.hasError && row.category == null ? 1.5 : 1.0
                                      ),
                                      borderRadius: BorderRadius.circular(6)
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                            row.category ?? (row.hasError ? "Required Field" : "Select Category"),
                                            style: TextStyle(
                                                fontSize: 13,
                                                // Specific Text Color Error for Category Field
                                                color: row.category == null ? (row.hasError ? Colors.red : Colors.grey) : Colors.black87,
                                                fontWeight: row.category == null && row.hasError ? FontWeight.bold : FontWeight.normal
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                      ),
                                      Icon(Icons.expand_more, size: 18, color: row.hasError ? Colors.red : Colors.black54)
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextField(
                                controller: row.memoController,
                                decoration: InputDecoration(
                                  hintText: "Item Memo (e.g. Cables for Office)",
                                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: Colors.grey.shade300)
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: Colors.grey.shade300)
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          ],
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

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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