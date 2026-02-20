import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../logic/transaction_provider.dart';
import '../../models/entity_model.dart';
import 'triage_bottom_sheet.dart';

class SmartTriageSheet extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const SmartTriageSheet({super.key, required this.transaction});

  @override
  State<SmartTriageSheet> createState() => _SmartTriageSheetState();
}

class _SmartTriageSheetState extends State<SmartTriageSheet> {
  String? _selectedEntityId;
  String? _selectedCategory;
  final TextEditingController _noteController = TextEditingController(); // Controller for Memo

  bool _isProcessing = false;
  bool _isSuggestion = false;

  @override
  void initState() {
    super.initState();
    _checkSmartMatch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkSmartMatch();
  }

  Future<void> _checkSmartMatch() async {
    if (_selectedEntityId != null || _selectedCategory != null) return;

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

  // --- SMART MATCH INFO TOOLTIP ---
  void _showSmartMatchInfo() {
    final sjNavy = Theme.of(context).colorScheme.secondary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: sjNavy, size: 24),
                  const SizedBox(width: 12),
                  Text("Smart Match Engine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sjNavy)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                  "BEAMS uses Historical Exact Matching.\n\nIf you have 3 consecutive transactions from the same merchant with the same category, BEAMS will auto-suggest the split.",
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: sjNavy, foregroundColor: Colors.white),
                  child: const Text("GOT IT"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- TAX LOGIC SHEET ---
  void _showTaxLogicSheet() {
    final sjNavy = Theme.of(context).colorScheme.secondary;
    final sjTeal = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey.shade300)),
              const SizedBox(height: 20),
              Text("Why these categories?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: sjNavy)),
              const SizedBox(height: 16),

              _buildInfoSection("1. Tax Prep Efficiency", "If your records match the IRS Schedule C forms, filing taxes takes minutes, not hours.", Icons.timer, sjTeal),
              _buildInfoSection("2. Audit Defense", "Using these standard categories creates an instant, clean paper trail.", Icons.shield, sjTeal),

              const Divider(height: 40),
              Text("Mapping Modern Expenses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sjNavy)),
              const SizedBox(height: 10),
              _buildMappingRow("Software / SaaS", "Office Expense (or Software Subscriptions)"),
              _buildMappingRow("Web Hosting", "Advertising"),
              _buildMappingRow("Online Courses", "Education & Training"),

              const Divider(height: 40),
              Text("The 'Sub-Category' Strategy", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sjNavy)),
              const SizedBox(height: 10),
              Text("Use the IRS Category as the 'Parent' and your transaction note as the 'Child'.", style: TextStyle(color: Colors.grey.shade700, height: 1.5)),

              const SizedBox(height: 40),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("GOT IT"))
            ],
          ),
        )
    );
  }

  Widget _buildInfoSection(String title, String body, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMappingRow(String modern, String irs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(modern, style: const TextStyle(fontWeight: FontWeight.w500))),
          const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(irs, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
        ],
      ),
    );
  }

  // --- STREAM PICKER ---
  void _openStreamPicker(List<Entity> entities) {
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
                  final bool isSelected = _selectedEntityId == e.id;

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
                        _selectedEntityId = e.id;
                        _isSuggestion = false; // User manually overrode
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
  void _openCategoryPicker(List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  TextButton(
                    onPressed: _showTaxLogicSheet,
                    child: Text("Why these?", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final bool isSelected = _selectedCategory == cat['name'];

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
                        _selectedCategory = cat['name'];
                        _isSuggestion = false;
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

  void _handleDirectCommit() async {
    if (_selectedEntityId == null || _selectedCategory == null) return;
    setState(() => _isProcessing = true);

    final provider = context.read<TransactionProvider>();
    final amountCents = widget.transaction['amount_cents'] as int;

    // Use the note from the controller as the memo for this single split
    final List<Map<String, dynamic>> singleSplit = [{
      'entityId': _selectedEntityId,
      'amount': amountCents,
      'category': _selectedCategory,
      'memo': _noteController.text
    }];

    await provider.finalizeSplit(
        transactionId: widget.transaction['transaction_id'],
        splitRows: singleSplit,
        note: _noteController.text // Also save as transaction note
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _openAdvancedSplit() {
    // Save draft state (including memo) before switching
    if (_noteController.text.isNotEmpty) {
      context.read<TransactionProvider>().saveDraft(widget.transaction['transaction_id'], note: _noteController.text);
    }

    Navigator.pop(context);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TriageBottomSheet(
            transaction: widget.transaction,
            onComplete: (success) {}
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final tfeGreen = Theme.of(context).colorScheme.primary;
    final sjTeal = Theme.of(context).colorScheme.primary;

    final currency = NumberFormat.simpleCurrency();
    final int amountCents = widget.transaction['amount_cents'] as int;
    final double amount = amountCents / 100.0;

    final provider = context.watch<TransactionProvider>();
    final accountName = widget.transaction['institution_name'] ?? 'Unknown Acct';
    final bool canCommit = _selectedEntityId != null && _selectedCategory != null;

    final bool isCredit = amountCents < 0;
    final List<Map<String, dynamic>> categoryList = isCredit ? AppConstants.creditCategories : AppConstants.debitCategories;

    String streamDisplay = "Select Stream";
    if (_selectedEntityId != null) {
      try { streamDisplay = provider.entities.firstWhere((e) => e.id == _selectedEntityId).name; } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, color: Colors.black12)),
            const SizedBox(height: 24),

            if (_isSuggestion)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: _showSmartMatchInfo,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 6),
                      Text(
                          "SMART MATCH FOUND",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary, letterSpacing: 1.0)
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline, size: 12, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),

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
                      Row(
                        children: [
                          Text(widget.transaction['date'].toString().substring(0, 10), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.circle, size: 4, color: Colors.grey.shade300)),
                          Expanded(
                            child: Text(accountName, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(amount.abs()),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: tfeGreen, letterSpacing: -1.0),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            Text("ASSIGN TO STREAM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openStreamPicker(provider.entities),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                            streamDisplay,
                            style: TextStyle(fontSize: 14, color: _selectedEntityId == null ? Colors.grey.shade600 : Colors.black87, fontWeight: _selectedEntityId == null ? FontWeight.normal : FontWeight.w600),
                            overflow: TextOverflow.ellipsis
                        )
                    ),
                    Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text("ASSIGN CATEGORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openCategoryPicker(categoryList),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                            _selectedCategory ?? "Select Category",
                            style: TextStyle(fontSize: 14, color: _selectedCategory == null ? Colors.grey.shade600 : Colors.black87, fontWeight: _selectedCategory == null ? FontWeight.normal : FontWeight.w600),
                            overflow: TextOverflow.ellipsis
                        )
                    ),
                    Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600)
                  ],
                ),
              ),
            ),

            // --- ADDED MISSING MEMO FIELD ---
            const SizedBox(height: 16),
            Text("MEMO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "e.g. Microphone, Client Dinner",
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)
                ),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)
                ),
                prefixIcon: Icon(Icons.notes, size: 20, color: sjTeal),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (val) {
                provider.saveDraft(widget.transaction['transaction_id'], note: val);
              },
            ),
            // --------------------------------

            const SizedBox(height: 32),

            Row(
              children: [
                TextButton.icon(
                  onPressed: _openAdvancedSplit,
                  icon: const Icon(Icons.call_split, size: 20, color: Colors.black54),
                  label: const Text("Split", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
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

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}