import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TriageCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TriageCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Format Cents to Dollars [Source 63]
    final double amount = (transaction['amount_cents'] as int) / 100.0;
    final currencyFormat = NumberFormat.simpleCurrency();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Merchant Name
            Text(
              transaction['merchant_name'],
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Amount
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900, // Heavy weight for impact
                  color: Colors.blueGrey
              ),
            ),
            const SizedBox(height: 10),

            // Date
            Text(
              transaction['date'],
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey
              ),
            ),

            const Spacer(),

            // Hint Text for User
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("← Personal", style: TextStyle(color: Colors.red)),
                Text("Business →", style: TextStyle(color: Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }
}