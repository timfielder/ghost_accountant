import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // REQUIRED FOR ALERTS
import '../../logic/transaction_provider.dart';
import '../widgets/quick_triage_card.dart';

class TriageScreen extends StatelessWidget {
  const TriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ALLOCATE"),
        centerTitle: true,
      ),
      // THE "LIVE FIRE" SIMULATION BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.grey.shade800,
        icon: const Icon(Icons.notifications_active, color: Colors.white),
        label: const Text("Simulate Alert", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final provider = context.read<TransactionProvider>();
          final plugin = FlutterLocalNotificationsPlugin();
          final androidImplementation = plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

          if (androidImplementation != null) {
            await androidImplementation.requestNotificationsPermission();
          }

          // Generate Ghost Data
          final int amountCents = 4500 + (DateTime.now().millisecondsSinceEpoch % 15000);
          final String txId = 'tx_${DateTime.now().millisecondsSinceEpoch}';
          final double amountDol = amountCents / 100.0;
          final String merchant = "Amazon Web Services";

          final db = await provider.dbHelper.database;
          await db.insert('transactions', {
            'transaction_id': txId,
            'account_id': 'acct_123',
            'amount_cents': amountCents,
            'merchant_name': merchant,
            'date': DateTime.now().toIso8601String(),
            'status': 'PENDING'
          });

          // ignore: use_build_context_synchronously
          provider.loadInitialData('user_01');

          const androidDetails = AndroidNotificationDetails(
            'channel_id',
            'Transaction Alerts',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            color: Color(0xFF00264C), // SJ NAVY BRAND
          );
          const iosDetails = DarwinNotificationDetails();
          const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

          await plugin.show(
              0,
              'BEAMS • Action Required', // FIXED: Pluralized BEAMS
              '$merchant: \$${amountDol.toStringAsFixed(2)}',
              details,
              payload: txId
          );
        },
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.black12),
                  const SizedBox(height: 10),
                  Text("ALL CAUGHT UP", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black26)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.queue.length,
            itemBuilder: (context, index) {
              final tx = provider.queue[index];
              return QuickTriageCard(transaction: tx);
            },
          );
        },
      ),
    );
  }
}