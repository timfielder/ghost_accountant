import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../logic/transaction_provider.dart';
import '../widgets/triage_bottom_sheet.dart';

class TriageScreen extends StatelessWidget {
  const TriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tfeGreen = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ALLOCATE"),
        actions: [],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.black12), // Subtle Black, not BlueGrey
                  const SizedBox(height: 10),
                  Text("ALL CAUGHT UP", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black26)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.queue.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12), // Spacing instead of divider
            itemBuilder: (context, index) {
              final tx = provider.queue[index];
              final amount = (tx['amount_cents'] as int) / 100.0;
              final currency = NumberFormat.simpleCurrency().format(amount);
              final isAmazon = tx['merchant_name'].toString().contains('Amazon');

              return Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12, width: 1.5), // SHARP BORDER
                    borderRadius: BorderRadius.circular(4), // Architectural/Square
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  // Leading Icon: Crisp Black or Green
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAmazon ? Colors.orange.withOpacity(0.1) : tfeGreen.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAmazon ? Icons.shopping_cart : Icons.credit_card,
                      color: isAmazon ? Colors.deepOrange : tfeGreen,
                      size: 20,
                    ),
                  ),

                  title: Text(
                    tx['merchant_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    tx['date'].toString().substring(0, 10),
                    style: TextStyle(color: Colors.black54, fontSize: 12), // Darker Grey
                  ),

                  trailing: Text(
                    currency,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tfeGreen // Money is Green
                    ),
                  ),

                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => TriageBottomSheet(
                          transaction: tx,
                          onComplete: (success) {},
                        )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}