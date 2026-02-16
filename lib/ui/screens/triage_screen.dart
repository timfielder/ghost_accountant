import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../logic/transaction_provider.dart';
import '../widgets/triage_bottom_sheet.dart';

class TriageScreen extends StatelessWidget {
  const TriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Triage Queue"), // The "Backlog"
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // FIRE DRILL BUTTON (Preserved for testing Shortcuts)
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.deepOrange),
            tooltip: "Simulate Incoming Transaction",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Simulation Started: WAIT 5 SECONDS..."),
                    backgroundColor: Colors.deepOrange,
                    duration: Duration(seconds: 4),
                  )
              );
              await Future.delayed(const Duration(seconds: 5));
              if (context.mounted) {
                context.read<TransactionProvider>().triggerFireDrill((title, body, payload) async {
                  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
                  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                      'ghost_channel', 'Ghost Transactions', importance: Importance.max, priority: Priority.high
                  );
                  await flutterLocalNotificationsPlugin.show(
                      0, title, body, NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
                      payload: payload
                  );
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            tooltip: "Seed Test Data",
            onPressed: () => context.read<TransactionProvider>().seedDatabase(),
          )
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.blueGrey.shade200),
                  const SizedBox(height: 10),
                  const Text("All Caught Up!", style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
                ],
              ),
            );
          }

          // THE BACKLOG (Smart List View)
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.queue.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = provider.queue[index];
              final amount = (tx['amount_cents'] as int) / 100.0;
              final currency = NumberFormat.simpleCurrency().format(amount);

              // Visual Hint: Orange for Amazon (based on your sources)
              final isAmazon = tx['merchant_name'].toString().contains('Amazon');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                // Leading Icon (Quick ID)
                leading: CircleAvatar(
                  backgroundColor: isAmazon ? Colors.orange.shade100 : Colors.blueGrey.shade50,
                  child: Icon(
                      isAmazon ? Icons.shopping_cart : Icons.credit_card,
                      color: isAmazon ? Colors.deepOrange : Colors.blueGrey
                  ),
                ),

                // Merchant
                title: Text(
                  tx['merchant_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                // Date Metadata
                subtitle: Text(
                  tx['date'].toString().substring(0, 10),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),

                // Amount
                trailing: Text(
                  currency,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),

                // INTERACTION: Manual "Backlog" Triage
                onTap: () {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => TriageBottomSheet(
                        transaction: tx,
                        onComplete: (success) {
                          // The list updates automatically via Provider
                        },
                      )
                  );
                },
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F5F7),
    );
  }
}