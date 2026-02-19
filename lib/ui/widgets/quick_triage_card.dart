import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import 'triage_bottom_sheet.dart';

class QuickTriageCard extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const QuickTriageCard({super.key, required this.transaction});

  @override
  State<QuickTriageCard> createState() => _QuickTriageCardState();
}

class _QuickTriageCardState extends State<QuickTriageCard> {
  String? _selectedEntityId;
  String? _selectedCategory;
  bool _isProcessing = false;
  bool _isSuggestion = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestion();
  }

  Future<void> _loadSuggestion() async {
    final provider = context.read<TransactionProvider>();
    final suggestion = await provider.getStrictSuggestion(widget.transaction['merchant_name']);

    if (suggestion != null && mounted) {
      setState(() {
        _selectedEntityId = suggestion['entityId'];
        _selectedCategory = suggestion['category'];
        _isSuggestion = true;
      });
    }
  }

  void _handleDirectCommit() async {
    if (_selectedEntityId == null || _selectedCategory == null) return;

    setState(() => _isProcessing = true);
    final provider = context.read<TransactionProvider>();
    final amountCents = widget.transaction['amount_cents'] as int;

    final List<Map<String, dynamic>> singleSplit = [{
      'entityId': _selectedEntityId,
      'amount': amountCents,
      'category': _selectedCategory
    }];

    await provider.finalizeSplit(
        transactionId: widget.transaction['transaction_id'],
        splitRows: singleSplit
    );
  }

  void _openAdvancedSplit() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TriageBottomSheet(
          transaction: widget.transaction,
          onComplete: (success) {},
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    // BRAND COLORS
    final sjNavy = Theme.of(context).colorScheme.secondary;
    final sjTeal = Theme.of(context).colorScheme.primary;

    final currency = NumberFormat.simpleCurrency();
    final int amountCents = widget.transaction['amount_cents'] as int;
    final double amount = amountCents / 100.0;

    final provider = context.watch<TransactionProvider>();
    final accountName = widget.transaction['institution_name'] ?? 'Unknown Acct';
    final bool canCommit = _selectedEntityId != null && _selectedCategory != null;

    // INTELLIGENT CONTEXT
    // If amount is negative, it's a Credit (Income). If positive, it's a Debit (Expense).
    // Note: Adjust logic if your API uses a different sign convention.
    final bool isCredit = amountCents < 0;

    // FILTER THE LISTS (Progressive Disclosure)
    final List<Map<String, dynamic>> categoryList = isCredit
        ? AppConstants.creditCategories
        : AppConstants.debitCategories;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(
            // Visual Cue: Gold for Logic, Teal for Manual (Brand Alignment)
              color: _isSuggestion ? const Color(0xFFE0B42D) : sjTeal,
              width: 4
          )),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // SUGGESTION BANNER
              if (_isSuggestion)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 4),
                      Text(
                          "SMART MATCH FOUND",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.tertiary,
                              letterSpacing: 1.0
                          )
                      ),
                    ],
                  ),
                ),

              // --- TOP ROW: Merchant & Amount ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            widget.transaction['merchant_name'],
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
                        ),
                        const SizedBox(height: 6),
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
                    currency.format(amount.abs()),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        // COLOR PSYCHOLOGY: Teal for Income, Navy for Expense (No "Red Sea")
                        color: isCredit ? sjTeal : sjNavy,
                        letterSpacing: -0.5
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // --- MIDDLE ROW: Selectors ---
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEntityId,
                          hint: Text("Stream", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          isExpanded: true,
                          icon: Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600),
                          items: provider.entities.map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) => setState(() {
                            _selectedEntityId = val;
                            _isSuggestion = false;
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: Text("Category", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          isExpanded: true,
                          icon: Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600),
                          // CHANGED: Uses the filtered list (Credits vs Debits)
                          items: categoryList.map((cat) => DropdownMenuItem(
                            value: cat['name'] as String,
                            child: Row(
                              children: [
                                Icon(cat['icon'], size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(child: Text(cat['name'], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) => setState(() {
                            _selectedCategory = val;
                            _isSuggestion = false;
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- BOTTOM ROW: Actions ---
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _openAdvancedSplit,
                    icon: const Icon(Icons.call_split, size: 18, color: Colors.black54),
                    label: const Text("Split", style: TextStyle(color: Colors.black54)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: (canCommit && !_isProcessing) ? _handleDirectCommit : null,
                    icon: _isProcessing
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: const Text("COMMIT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sjTeal,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}