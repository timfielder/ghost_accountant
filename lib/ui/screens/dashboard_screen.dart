import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/transaction_provider.dart';
import 'pnl_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // BRAND COLORS
    final tfeGreen = Theme.of(context).colorScheme.primary;
    final sjNavy = Theme.of(context).colorScheme.secondary;
    final currency = NumberFormat.simpleCurrency();

    // Text Style for the Header (High Contrast Navy)
    final headerStyle = TextStyle(
        letterSpacing: 4.0,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: sjNavy
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Removed Shadow for a crisp "Flat" look
        scrolledUnderElevation: 0, // Prevents color shift on scroll
        iconTheme: IconThemeData(color: sjNavy),

        // CUSTOM LOGOTYPE: B E [LOGO] M S
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("B E ", style: headerStyle),

            // DIRECT LOGO - SCALED UP
            Transform.scale(
              scale: 1.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Image.asset(
                  'assets/images/logo.png', // Source of Truth
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            Text(" M S", style: headerStyle),
          ],
        ),
        centerTitle: true,

        // THE NAVY DIVIDER
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: sjNavy, // The Foundation Color
            height: 4.0,
          ),
        ),
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
    final tfeGreen = Theme.of(context).colorScheme.primary;

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