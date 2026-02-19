import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import 'triage_bottom_sheet.dart';

class SmartTriageSheet extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const SmartTriageSheet({super.key, required this.transaction});

  @override
  State<SmartTriageSheet> createState() => _SmartTriageSheetState();
}

class _SmartTriageSheetState extends State<SmartTriageSheet> {
  // Logic mirrors QuickTriageCard: No Defaults.
  String? _selectedEntityId;
  String? _selectedCategory;
  bool _isProcessing = false;

  void _handleDirectCommit() async {
    if (_selectedEntityId == null || _selectedCategory == null) return;

    setState(() => _isProcessing = true);

    final provider = context.read<TransactionProvider>();
    final amountCents = widget.transaction['amount_cents'] as int;

    // 1. Construct 100% Split
    final List<Map<String, dynamic>> singleSplit = [{
      'entityId': _selectedEntityId,
      'amount': amountCents,
      'category': _selectedCategory
    }];

    // 2. Commit to DB
    await provider.finalizeSplit(
        transactionId: widget.transaction['transaction_id'],
        splitRows: singleSplit
    );

    // 3. Close the Sheet (This is the key difference from the Card)
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _openAdvancedSplit() {
    // Close this "Simple" sheet and open the "Advanced" one
    Navigator.pop(context);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TriageBottomSheet(
          transaction: widget.transaction,
          onComplete: (success) {
            // No action needed, provider updates UI
          },
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final tfeGreen = Theme.of(context).colorScheme.primary;
    final currency = NumberFormat.simpleCurrency();
    final double amount = (widget.transaction['amount_cents'] as int) / 100.0;
    final provider = context.watch<TransactionProvider>();
    final accountName = widget.transaction['institution_name'] ?? 'Unknown Acct';

    // Validation
    final bool canCommit = _selectedEntityId != null && _selectedCategory != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Keep padding
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      // WRAP IN SAFEAREA TO FIX ANDROID OVERLAP
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(child: Container(width: 40, height: 4, color: Colors.black12)),
            const SizedBox(height: 24),

            // --- HEADER (Merchant & Amount) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("INCOMING CHARGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(
                          widget.transaction['merchant_name'],
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)
                      ),
                      const SizedBox(height: 8),
                      // Trust Badge
                      Row(
                        children: [
                          Text(
                              widget.transaction['date'].toString().substring(0, 10),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.circle, size: 4, color: Colors.grey.shade300),
                          ),
                          Icon(Icons.credit_card, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              accountName,
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(amount),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: tfeGreen,
                      letterSpacing: -1.0
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // --- SELECTORS ---
            // 1. Stream
            Text("ASSIGN TO STREAM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedEntityId,
                  hint: Text("Select Stream", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  isExpanded: true,
                  icon: Icon(Icons.expand_more, color: Colors.grey.shade600),
                  items: provider.entities.map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedEntityId = val),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Category
            Text("ASSIGN CATEGORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text("Select Category", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  isExpanded: true,
                  icon: Icon(Icons.expand_more, color: Colors.grey.shade600),
                  items: AppConstants.allCategories.map((cat) => DropdownMenuItem(
                    value: cat['name'] as String,
                    child: Row(
                      children: [
                        Icon(cat['icon'], size: 16, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(child: Text(cat['name'], style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- ACTIONS ---
            Row(
              children: [
                // Split Button (Opens Advanced)
                TextButton.icon(
                  onPressed: _openAdvancedSplit,
                  icon: const Icon(Icons.call_split, size: 20, color: Colors.black54),
                  label: const Text("Split", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),

                const Spacer(),

                // Commit Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (canCommit && !_isProcessing) ? _handleDirectCommit : null,
                    icon: _isProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: const Text("COMMIT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tfeGreen,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              ],
            ),

            // Extra padding is now handled by SafeArea, but adding a tiny bit more doesn't hurt
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}