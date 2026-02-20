import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/transaction_provider.dart';
import '../../core/constants.dart';

class PnLSwipeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items; // List of {id, name}
  final int initialIndex;
  final bool isAccount;

  const PnLSwipeScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.isAccount
  });

  @override
  State<PnLSwipeScreen> createState() => _PnLSwipeScreenState();
}

class _PnLSwipeScreenState extends State<PnLSwipeScreen> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPremiumDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Premium Feature"),
          content: const Text("Exporting P&L snapshots is available in the Pro plan (\$49/mo)."),
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
    final currentItem = widget.items[_currentIndex];
    final sjNavy = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.isAccount ? "ACCOUNT LEDGER" : "STREAM P&L",
              style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(currentItem['name'], style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: sjNavy,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _showPremiumDialog,
          )
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _PnLPage(
            entityId: item['id'],
            isAccount: widget.isAccount,
            // Pass a Key to force rebuild if ID changes
            key: ValueKey(item['id']),
          );
        },
      ),
    );
  }
}

// --- INDIVIDUAL P&L PAGE ---
class _PnLPage extends StatelessWidget {
  final String entityId;
  final bool isAccount;

  const _PnLPage({super.key, required this.entityId, required this.isAccount});

  @override
  Widget build(BuildContext context) {
    final tfeGreen = Theme.of(context).primaryColor;
    final currency = NumberFormat.simpleCurrency();

    return FutureBuilder<Map<String, dynamic>>(
      future: isAccount
          ? context.read<TransactionProvider>().getAccountPnL(entityId)
          : context.read<TransactionProvider>().getEntityPnL(entityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,4))
                  ]
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

            _SectionHeader(isAccount ? "MONEY IN" : "INCOME"),
            ...isAccount
                ? income.entries.map((e) => _LineItem(e.key, e.value, isPositive: true))
                : AppConstants.incomeCategories.map((cat) {
              final name = cat['name'] as String;
              final amount = income[name] ?? 0.0;
              return _LineItem(name, amount, isPositive: true);
            }),
            if (income.isNotEmpty)
              _TotalLine("TOTAL", income.values.fold(0, (a, b) => a + b)),

            const SizedBox(height: 30),

            _SectionHeader(isAccount ? "MONEY OUT" : "EXPENSES"),
            ...isAccount
                ? expenses.entries.map((e) => _LineItem(e.key, e.value, isPositive: false))
                : AppConstants.expenseCategories.map((cat) {
              final name = cat['name'] as String;
              final amount = expenses[name] ?? 0.0;
              return _LineItem(name, amount, isPositive: false);
            }),
            if (expenses.isNotEmpty)
              _TotalLine("TOTAL", expenses.values.fold(0, (a, b) => a + b)),

            if (!isAccount) ...[
              const SizedBox(height: 30),
              _SectionHeader("TRANSFERS"),
              ...AppConstants.transferCategories.map((cat) {
                final name = cat['name'] as String;
                final amount = transfers[name] ?? 0.0;
                return _LineItem(name, amount, isPositive: true);
              }),
            ]
          ],
        );
      },
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
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: isZero ? Colors.black54 : Colors.black87), overflow: TextOverflow.ellipsis)),
          Text(
              currency.format(amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isZero ? Colors.black38 : (isPositive ? Colors.black : Colors.redAccent)
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