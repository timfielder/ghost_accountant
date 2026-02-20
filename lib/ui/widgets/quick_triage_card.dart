import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import '../../models/entity_model.dart';
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
  List<Map<String, dynamic>>? _complexTemplate;
  final TextEditingController _noteController = TextEditingController();

  bool _isProcessing = false;
  bool _isSuggestion = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final provider = context.read<TransactionProvider>();
    final txId = widget.transaction['transaction_id'];
    final draft = provider.triageDrafts[txId];

    if (draft != null) {
      if (mounted) {
        setState(() {
          if (draft['entityId'] != null) _selectedEntityId = draft['entityId'];
          if (draft['category'] != null) _selectedCategory = draft['category'];
          if (draft['note'] != null) _noteController.text = draft['note'];
        });
      }
      return;
    }

    final template = await provider.getSmartMatchTemplate(widget.transaction['merchant_name']);

    if (template != null && mounted) {
      if (template.length == 1) {
        setState(() {
          _selectedEntityId = template.first['entity_id'];
          _selectedCategory = template.first['category'];
          _isSuggestion = true;
        });
      } else {
        setState(() {
          _complexTemplate = template;
          _isSuggestion = true;
        });
      }
    }
  }

  void _showSmartMatchInfo() {
    // Info sheet code (same as before)
    showModalBottomSheet(
        context: context,
        builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: const Text("Smart Match: Based on previous 3 identical transactions.")
        )
    );
  }

  void _openStreamPicker(List<Entity> entities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ListView.builder(
        itemCount: entities.length,
        itemBuilder: (ctx, index) => ListTile(
          title: Text(entities[index].name),
          onTap: () {
            setState(() {
              _selectedEntityId = entities[index].id;
              _complexTemplate = null;
              _isSuggestion = false;
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _openCategoryPicker(List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ListView.builder(
        itemCount: categories.length,
        itemBuilder: (ctx, index) => ListTile(
          title: Text(categories[index]['name']),
          onTap: () {
            setState(() {
              _selectedCategory = categories[index]['name'];
              _complexTemplate = null;
              _isSuggestion = false;
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _handleCommit() async {
    setState(() => _isProcessing = true);

    try {
      final provider = context.read<TransactionProvider>();
      final amountCents = widget.transaction['amount_cents'] as int;
      List<Map<String, dynamic>> finalSplits = [];

      if (_complexTemplate != null) {
        int templateTotal = _complexTemplate!.fold(0, (sum, item) => sum + (item['amount_cents'] as int));

        for (var item in _complexTemplate!) {
          double ratio = (item['amount_cents'] as int) / templateTotal;
          int share = (amountCents * ratio).round();

          finalSplits.add({
            'entityId': item['entity_id'],
            'amount': share,
            'category': item['category'],
            'memo': _noteController.text
          });
        }

        // FIXED: Correctly accessing list item for penny fix
        int allocated = finalSplits.fold(0, (sum, item) => sum + (item['amount'] as int));
        int remainder = amountCents - allocated;
        if (remainder != 0 && finalSplits.isNotEmpty) {
          finalSplits.first['amount'] = (finalSplits.first['amount'] as int) + remainder;
        }

      } else {
        if (_selectedEntityId == null || _selectedCategory == null) return;
        finalSplits.add({
          'entityId': _selectedEntityId,
          'amount': amountCents,
          'category': _selectedCategory,
          'memo': _noteController.text
        });
      }

      await provider.finalizeSplit(
          transactionId: widget.transaction['transaction_id'],
          splitRows: finalSplits,
          note: _noteController.text
      );

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error committing.")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openAdvancedSplit() {
    if (_noteController.text.isNotEmpty) {
      context.read<TransactionProvider>().saveDraft(widget.transaction['transaction_id'], note: _noteController.text);
    }
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TriageBottomSheet(transaction: widget.transaction, onComplete: (success) {})
    );
  }

  @override
  Widget build(BuildContext context) {
    final sjNavy = Theme.of(context).colorScheme.secondary;
    final sjTeal = Theme.of(context).colorScheme.primary;
    final currency = NumberFormat.simpleCurrency();
    final int amountCents = widget.transaction['amount_cents'] as int;
    final double amount = amountCents / 100.0;
    final provider = context.watch<TransactionProvider>();

    final bool isComplex = _complexTemplate != null;
    final bool canCommit = isComplex || (_selectedEntityId != null && _selectedCategory != null);

    String streamDisplay = "Stream";
    if (isComplex) {
      streamDisplay = "Multi-Stream Split";
    } else if (_selectedEntityId != null) {
      try { streamDisplay = provider.entities.firstWhere((e) => e.id == _selectedEntityId).name; } catch (_) {}
    }

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.transaction['merchant_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(currency.format(amount.abs()), style: TextStyle(fontWeight: FontWeight.bold, color: sjTeal)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openStreamPicker(provider.entities),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Text(streamDisplay),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openCategoryPicker(AppConstants.debitCategories), // Simplified for brevity
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Text(isComplex ? "Multi-Category" : (_selectedCategory ?? "Category")),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "Memo",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              onChanged: (val) => provider.saveDraft(widget.transaction['transaction_id'], note: val),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: _openAdvancedSplit, child: const Text("Split")),
                const Spacer(),
                ElevatedButton(onPressed: canCommit ? _handleCommit : null, child: const Text("COMMIT"))
              ],
            )
          ],
        ),
      ),
    );
  }
}