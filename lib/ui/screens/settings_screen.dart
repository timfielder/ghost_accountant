import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/export_service.dart';
import '../../models/entity_model.dart';
import 'onboarding_screen.dart';

void _showTooltip(BuildContext context, String title, String message, Color brandColor) {
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
                Icon(Icons.info_outline, color: brandColor, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandColor))),
              ],
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text("GOT IT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            )
          ],
        ),
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  void _showEntityDialog(BuildContext context, {Entity? existingEntity}) {
    final controller = TextEditingController(text: existingEntity?.name ?? "");
    final isEdit = existingEntity != null;

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isEdit ? "Edit Stream" : "Add Stream"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Stream Name"),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final provider = context.read<TransactionProvider>();
                  if (isEdit) {
                    provider.updateEntity(existingEntity.id, controller.text);
                  } else {
                    provider.addEntity(controller.text, isPrimary: false);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEdit ? "SAVE" : "ADD", style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        )
    );
  }

  void _showAccountDialog(BuildContext context, {Map<String, dynamic>? existingAccount}) {
    final provider = context.read<TransactionProvider>();
    final nameController = TextEditingController(text: existingAccount != null ? existingAccount['institution_name'] : "");
    final balanceController = TextEditingController(text: "...");
    final notesController = TextEditingController();

    final isEdit = existingAccount != null;

    // State for logic detection
    double originalCalculatedBalance = 0.0;

    // 0 = Create Adjustment (Default Recommended)
    // 1 = Rewrite History
    // null = No Selection Made
    int? selectedOption;

    if (isEdit) {
      provider.getCalculatedBalance(existingAccount['account_id']).then((val) {
        originalCalculatedBalance = val;
        balanceController.text = val.toStringAsFixed(2);
      });
    } else {
      balanceController.text = "0.00";
    }

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              final double currentInput = double.tryParse(balanceController.text) ?? 0.0;
              final bool hasBalanceChanged = (currentInput - originalCalculatedBalance).abs() > 0.009;

              // Disable save if balance changed but no option selected
              final bool canSave = nameController.text.isNotEmpty && (!isEdit || !hasBalanceChanged || selectedOption != null);

              return AlertDialog(
                title: Text(isEdit ? "Edit Account" : "Add Account"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(hintText: "Bank Name"),
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          labelText: isEdit ? "Current Balance" : "Starting Balance",
                          prefixText: "\$",
                        ),
                        onChanged: (_) => setState(() {
                          // Reset option if they change text to force re-evaluation
                          if (!hasBalanceChanged) selectedOption = null;
                        }),
                      ),

                      // LOGIC BLOCK: Only appears if user changed the balance number
                      if (isEdit && hasBalanceChanged) ...[
                        const SizedBox(height: 20),
                        const Text(
                            "How do you want to handle this adjustment?",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)
                        ),
                        const SizedBox(height: 8),

                        // OPTION A: ADJUSTMENT (RECOMMENDED)
                        RadioListTile<int>(
                          value: 0,
                          groupValue: selectedOption,
                          onChanged: (val) => setState(() => selectedOption = val),
                          title: const Text("Option A (Recommended)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text("Create an adjustment transaction that updates the current balance.", style: TextStyle(fontSize: 11)),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),

                        // NOTES FIELD (Only for Option A)
                        if (selectedOption == 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                            child: TextField(
                              controller: notesController,
                              decoration: const InputDecoration(
                                  labelText: "Justification / Note",
                                  hintText: "e.g., Bank Fee correction",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(10)
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),

                        // OPTION B: REWRITE HISTORY
                        RadioListTile<int>(
                          value: 1,
                          groupValue: selectedOption,
                          onChanged: (val) => setState(() => selectedOption = val),
                          title: const Text("Option B", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text("Adjust the entire history of this account for this period.", style: TextStyle(fontSize: 11)),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
                  TextButton(
                    onPressed: canSave ? () {
                      final bal = double.tryParse(balanceController.text) ?? 0.0;

                      if (isEdit) {
                        if (hasBalanceChanged) {
                          if (selectedOption == 0) {
                            provider.reconcileBalance(existingAccount['account_id'], nameController.text, bal, notesController.text);
                          } else if (selectedOption == 1) {
                            provider.updateAccountToTargetBalance(existingAccount['account_id'], nameController.text, bal);
                          }
                        } else {
                          provider.updateAccountNameOnly(existingAccount['account_id'], nameController.text);
                        }
                      } else {
                        provider.addAccount(nameController.text, bal);
                      }
                      Navigator.pop(ctx);
                    } : null, // Disabled
                    child: Text(isEdit ? "SAVE" : "ADD", style: TextStyle(fontWeight: FontWeight.bold, color: canSave ? Theme.of(context).primaryColor : Colors.grey)),
                  )
                ],
              );
            }
        )
    );
  }

  void _confirmDelete(BuildContext context, String name, VoidCallback onDelete) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Item?"),
          content: Text("Are you sure you want to remove '$name'?\n\nThis cannot be undone."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDelete();
              },
              child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            )
          ],
        )
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Premium Feature"),
          content: const Text("P&L Exports and Deep-Dive Reports are available in the Pro plan."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("UPGRADE")
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final entities = provider.entities;

    final sjNavy = Theme.of(context).colorScheme.secondary;
    final sjTeal = Theme.of(context).colorScheme.primary;
    final sjGold = Theme.of(context).colorScheme.tertiary;

    final headerStyle = const TextStyle(
        letterSpacing: 4.0,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.white
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: sjNavy,
        elevation: 0,
        centerTitle: true,
        title: Text("SYSTEM", style: headerStyle),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: provider.getAccounts(),
          builder: (context, snapshot) {
            final accounts = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [

                // 1. IDENTITY CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: sjNavy,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,4))]
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: sjGold,
                        child: Text("TF", style: TextStyle(color: sjNavy, fontWeight: FontWeight.bold, fontSize: 24)),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tim Fielder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text("tim@timfielder.com", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: sjTeal, borderRadius: BorderRadius.circular(4)),
                            child: const Text("ALPHA USER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 2. CONFIGURATION
                Text("CONFIGURATION", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                SwitchListTile(
                  value: provider.useSmartMatch,
                  onChanged: (val) => provider.toggleSmartMatch(val),
                  activeColor: sjTeal,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Row(
                    children: [
                      const Text("Smart Match Algorithm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showTooltip(
                            context,
                            "Smart Match Engine",
                            "BEAMS uses Historical Exact Matching.\n\nIf you have 3 consecutive transactions from the same merchant with the same category, BEAMS will auto-suggest the split.",
                            sjNavy
                        ),
                        child: Icon(Icons.info_outline, size: 16, color: sjTeal),
                      )
                    ],
                  ),
                  subtitle: const Text("Pre-fill categories for known merchants.", style: TextStyle(fontSize: 12)),
                  secondary: Icon(Icons.memory, color: provider.useSmartMatch ? sjGold : Colors.grey),
                ),

                const SizedBox(height: 32),

                // 3. STREAMS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ACTIVE STREAMS", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: sjTeal),
                      onPressed: () => _showEntityDialog(context),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                ...entities.map((e) => Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(e.isPrimary ? Icons.security : Icons.layers, color: e.isPrimary ? sjNavy : sjTeal),
                    title: Text(e.name, style: TextStyle(fontWeight: FontWeight.bold, color: sjNavy)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _showEntityDialog(context, existingEntity: e),
                        ),
                        if (!e.isPrimary)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _confirmDelete(context, e.name, () async {
                              bool success = await provider.deleteEntity(e.id);
                              if (!success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Action Blocked: This stream has active transactions."),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    )
                                );
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 32),

                // 4. ACCOUNTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("LINKED ACCOUNTS", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: sjTeal),
                      onPressed: () => _showAccountDialog(context),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                ...accounts.map((a) => Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.account_balance, color: sjNavy),
                    title: Text(a['institution_name'], style: TextStyle(fontWeight: FontWeight.bold, color: sjNavy)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _showAccountDialog(context, existingAccount: a),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => _confirmDelete(context, a['institution_name'], () async {
                            bool success = await provider.deleteAccount(a['account_id']);
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Action Blocked: This account has active transactions."),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  )
                              );
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 32),

                // 5. ACTIONS
                Text("ACTIONS", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Export P&L
                ListTile(
                  onTap: () => _showPremiumDialog(context),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: Icon(Icons.picture_as_pdf, color: sjNavy),
                  title: const Text("Export P&L Reports", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Detailed PDF/CSV reports for your CPA.", style: TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.lock, size: 16, color: sjGold),
                ),

                const SizedBox(height: 12),

                // Backup
                ListTile(
                  onTap: _isExporting ? null : () async {
                    setState(() => _isExporting = true);
                    try {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final Rect origin = box.localToGlobal(Offset.zero) & box.size;
                      await ExportService.generateAndShareCsv(origin);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Failed: $e"), backgroundColor: Colors.red));
                    } finally {
                      if (mounted) setState(() => _isExporting = false);
                    }
                  },
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: _isExporting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.share, color: sjNavy),
                  title: const Text("Backup Database (CSV)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Export your full history to Excel.", style: TextStyle(fontSize: 12)),
                ),

                const SizedBox(height: 12),

                // Close Period
                ListTile(
                  onTap: () {
                    final textController = TextEditingController();
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Close & Archive Books for this Period?"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("This prepares your system for a new period (e.g., New Tax Year or Quarter).\n\n1. All account balances will update to match current totals.\n2. Transaction history will be exported to CSV and then wiped from the device.\n\nType 'ARCHIVE' below to confirm:"),
                              const SizedBox(height: 12),
                              TextField(
                                controller: textController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "ARCHIVE"),
                              )
                            ],
                          ),
                          actions: [
                            TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(ctx)),
                            TextButton(
                                child: const Text("CONFIRM CLOSE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  if (textController.text == "ARCHIVE") {
                                    Navigator.pop(ctx);
                                    final RenderBox box = context.findRenderObject() as RenderBox;
                                    final Rect origin = box.localToGlobal(Offset.zero) & box.size;
                                    await provider.startNewYearProtocol(origin);
                                  }
                                }
                            ),
                          ],
                        )
                    );
                  },
                  tileColor: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.archive, color: Colors.orange),
                  title: const Text("Close & Archive Books for this Period", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  subtitle: const Text("Reset transactions for a new period.", style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                ),

                const SizedBox(height: 12),

                // Reset
                ListTile(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Factory Reset?"),
                          content: const Text("This will wipe ALL data and return you to the onboarding screen."),
                          actions: [
                            TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(ctx)),
                            TextButton(
                                child: const Text("WIPE DATA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await provider.resetDatabase();
                                  Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                                          (route) => false
                                  );
                                }
                            ),
                          ],
                        )
                    );
                  },
                  tileColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Factory Reset", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: const Text("Wipe everything.", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text("BEAMS v1.0.3 (Alpha Build)", style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
      ),
    );
  }
}