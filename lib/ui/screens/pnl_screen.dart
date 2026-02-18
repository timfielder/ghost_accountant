import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/transaction_provider.dart';
import '../../core/constants.dart'; // REQUIRED for category lists

class PnLScreen extends StatelessWidget {
  final String entityId;
  final String entityName;
  final bool isAccount;

  const PnLScreen({
    super.key,
    required this.entityId,
    required this.entityName,
    this.isAccount = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final tfeGreen = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(entityName.toUpperCase()), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: isAccount
            ? context.read<TransactionProvider>().getAccountPnL(entityId)
            : context.read<TransactionProvider>().getEntityPnL(entityId),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Even if empty, we want to show the list of 0.00s
          final data = snapshot.data ?? {};
          final Map<String, double> income = Map<String, double>.from(data['income'] ?? {});
          final Map<String, double> expenses = Map<String, double>.from(data['expenses'] ?? {});
          final Map<String, double> transfers = Map<String, double>.from(data['transfers'] ?? {});
          final double net = data['netIncome'] ?? 0.0;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // NET PROFIT/FLOW CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: net >= 0 ? tfeGreen : Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(isAccount ? "NET FLOW" : "NET PROFIT", style: const TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(currency.format(net), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // INCOME SECTION (Full List)
              _SectionHeader("INCOME"),
              ...AppConstants.incomeCategories.map((cat) {
                final name = cat['name'] as String;
                final amount = income[name] ?? 0.0;
                return _LineItem(name, amount, isPositive: true);
              }),
              _TotalLine("TOTAL INCOME", income.values.fold(0, (a, b) => a + b)),

              const SizedBox(height: 30),

              // EXPENSE SECTION (Full List)
              _SectionHeader("EXPENSES"),
              ...AppConstants.expenseCategories.map((cat) {
                final name = cat['name'] as String;
                final amount = expenses[name] ?? 0.0;
                return _LineItem(name, amount, isPositive: false);
              }),
              _TotalLine("TOTAL EXPENSES", expenses.values.fold(0, (a, b) => a + b)),

              const SizedBox(height: 30),

              // TRANSFERS SECTION (Full List)
              _SectionHeader("TRANSFERS"),
              ...AppConstants.transferCategories.map((cat) {
                final name = cat['name'] as String;
                final amount = transfers[name] ?? 0.0;
                return _LineItem(name, amount, isPositive: true);
              }),
            ],
          );
        },
      ),
    );
  }
}

// Helpers
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPositive;
  const _LineItem(this.label, this.amount, {required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final bool isZero = amount == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: isZero ? Colors.black38 : Colors.black87), overflow: TextOverflow.ellipsis)),
          Text(
              currency.format(amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isZero ? Colors.black26 : (isPositive ? Colors.black : Colors.redAccent)
              )
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final double amount;
  const _TotalLine(this.label, this.amount);
  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    return Container(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(currency.format(amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}