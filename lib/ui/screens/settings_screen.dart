import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/export_service.dart'; // Import the engine we just fixed
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final entities = provider.entities;

    // COMPASS PALETTE
    final sjNavy = Theme.of(context).colorScheme.secondary;
    final sjTeal = Theme.of(context).colorScheme.primary;
    final sjGold = Theme.of(context).colorScheme.tertiary;

    final headerStyle = TextStyle(
        letterSpacing: 4.0,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: sjNavy
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("SYSTEM", style: headerStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: sjNavy, height: 4.0),
        ),
      ),
      body: Builder(
          builder: (BuildContext context) {
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

                // 2. TOGGLES & CONFIG
                Text("CONFIGURATION", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                SwitchListTile(
                  value: provider.useSmartMatch,
                  onChanged: (val) => provider.toggleSmartMatch(val),
                  activeColor: sjTeal,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: const Text("Smart Match Algorithm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Pre-fill categories for known merchants.", style: TextStyle(fontSize: 12)),
                  secondary: Icon(Icons.auto_awesome, color: provider.useSmartMatch ? sjGold : Colors.grey),
                ),

                const SizedBox(height: 32),

                // 3. ACTIVE STREAMS
                Text("ACTIVE STREAMS", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...entities.map((e) => Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200)
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(e.isPrimary ? Icons.security : Icons.water_drop, color: e.isPrimary ? sjNavy : sjTeal),
                    title: Text(e.name, style: TextStyle(fontWeight: FontWeight.bold, color: sjNavy)),
                    subtitle: Text(e.isPrimary ? "Umbrella Entity (Default)" : "Business Stream", style: const TextStyle(fontSize: 12)),
                  ),
                )),

                const SizedBox(height: 32),

                // 4. DATA SECURITY (The Escape Hatch)
                Text("DATA SECURITY", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // BACKUP BUTTON (The Premium Feature)
                ListTile(
                  onTap: _isExporting ? null : () async {
                    setState(() => _isExporting = true);
                    try {
                      // 1. Calculate the Share Origin (Required for iOS)
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final Rect origin = box.localToGlobal(Offset.zero) & box.size;

                      // 2. Call Service with Origin
                      await ExportService.generateAndShareCsv(origin);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Export ready. Check your share sheet."))
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Export Failed: $e"), backgroundColor: Colors.red)
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isExporting = false);
                    }
                  },
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: _isExporting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.ios_share, color: sjNavy),
                  title: const Text("Backup Database (CSV)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Export your full history to Excel/Numbers.", style: TextStyle(fontSize: 12)),
                ),

                const SizedBox(height: 12),

                // RESET BUTTON
                ListTile(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Factory Reset?"),
                          content: const Text("This will wipe all data and return you to the onboarding screen. This cannot be undone."),
                          actions: [
                            TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(ctx)),
                            TextButton(
                                child: const Text("WIPE DATA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await provider.resetDatabase();
                                  // ignore: use_build_context_synchronously
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
                  subtitle: const Text("Wipe all local data from this device.", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
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