import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/transaction_provider.dart';
import 'pnl_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // BEAMS COLORS
    final tfeGreen = Theme.of(context).primaryColor;
    final currency = NumberFormat.simpleCurrency();

    // Text Style for the Header (High Contrast White)
    const headerStyle = TextStyle(
        letterSpacing: 4.0, // Wide spacing for luxury feel
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.white
    );

    return Scaffold(
      appBar: AppBar(
        // CUSTOM LOGOTYPE: B E [A] M S
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("B E", style: headerStyle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              // Your Prism Logo acts as the "A"
              child: Image.asset(
                'assets/images/logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const Text("M S", style: headerStyle),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: context.watch<TransactionProvider>().getDashboardMetrics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final double netProfit = data['netProfit'] ?? 0.0;
          final List streams = data['streamLeaderboard'] ?? [];
          final List accounts = data['accountLeaderboard'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. MACRO VIEW (Portfolio Net)
                Text("PORTFOLIO NET", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  currency.format(netProfit),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: netProfit >= 0 ? tfeGreen : Colors.redAccent,
                  ),
                ),

                const SizedBox(height: 30),

                // 2. MICRO VIEW (Stream Performance)
                Text("STREAM PERFORMANCE", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                if (streams.isEmpty) const Text("No streams active.", style: TextStyle(color: Colors.grey)),

                ...streams.map((item) => _PerformanceCard(
                  name: item['name'],
                  amount: item['net'],
                  onTap: () {
                    // Navigate to Entity P&L
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => PnLScreen(
                          entityId: item['id'],
                          entityName: item['name'],
                          isAccount: false,
                        )
                    ));
                  },
                )),

                const SizedBox(height: 30),

                // 3. ACCOUNT VIEW (Bank Health)
                Text("ACCOUNTS", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                if (accounts.isEmpty) const Text("No accounts linked.", style: TextStyle(color: Colors.grey)),

                ...accounts.map((item) => _PerformanceCard(
                  name: item['name'],
                  amount: item['net'],
                  isAccount: true,
                  onTap: () {
                    // Navigate to Account P&L
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => PnLScreen(
                          entityId: item['id'],
                          entityName: item['name'],
                          isAccount: true,
                        )
                    ));
                  },
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Reusable Card Component
class _PerformanceCard extends StatelessWidget {
  final String name;
  final double amount;
  final VoidCallback onTap;
  final bool isAccount;

  const _PerformanceCard({
    super.key,
    required this.name,
    required this.amount,
    required this.onTap,
    this.isAccount = false
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final isProfitable = amount >= 0;
    final tfeGreen = Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
            ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (!isAccount)
                  Text(
                      isProfitable ? "CONTRIBUTOR" : "SUBSIDIZED",
                      style: TextStyle(
                          color: isProfitable ? tfeGreen : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0
                      )
                  ),
              ],
            ),
            Text(
              currency.format(amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isProfitable ? Colors.black : Colors.red
              ),
            )
          ],
        ),
      ),
    );
  }
}