import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/transaction_provider.dart';
import 'pnl_screen.dart'; // Using the new Swipe Screen

// --- HELPER TOOLTIP MODAL ---
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // BRAND COLORS
    final tfeGreen = Theme.of(context).colorScheme.primary;
    final sjNavy = Theme.of(context).colorScheme.secondary;

    final currency = NumberFormat.simpleCurrency();

    final headerStyle = TextStyle(
        letterSpacing: 4.0,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: sjNavy
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: sjNavy),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("B E ", style: headerStyle),
            Transform.scale(
              scale: 1.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Image.asset('assets/images/logo.png', height: 38, fit: BoxFit.contain),
              ),
            ),
            Text(" M S", style: headerStyle),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: sjNavy, height: 4.0),
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
                // 1. MACRO VIEW
                Text("PORTFOLIO NET", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  currency.format(netProfit),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: netProfit >= 0 ? tfeGreen : Colors.redAccent),
                ),

                const SizedBox(height: 30),

                // 2. MICRO VIEW (Stream Performance)
                Text("STREAM PERFORMANCE", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                if (streams.isEmpty) const Text("No streams active.", style: TextStyle(color: Colors.grey)),

                // Using asMap().entries to get the INDEX needed for Swiping
                ...streams.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _PerformanceCard(
                    name: item['name'],
                    amount: item['net'],
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PnLSwipeScreen(
                              items: List<Map<String, dynamic>>.from(streams),
                              initialIndex: index,
                              isAccount: false
                          )
                      ));
                    },
                  );
                }),

                const SizedBox(height: 30),

                // 3. ACCOUNT VIEW (Bank Health)
                Text("ACCOUNTS", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                if (accounts.isEmpty) const Text("No accounts linked.", style: TextStyle(color: Colors.grey)),

                ...accounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _PerformanceCard(
                    name: item['name'],
                    amount: item['net'],
                    isAccount: true,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PnLSwipeScreen(
                              items: List<Map<String, dynamic>>.from(accounts),
                              initialIndex: index,
                              isAccount: true
                          )
                      ));
                    },
                  );
                }),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                  if (!isAccount) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                            isProfitable ? "CONTRIBUTOR" : "SUBSIDIZED",
                            style: TextStyle(
                                color: isProfitable ? tfeGreen : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0
                            )
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showTooltip(
                              context,
                              isProfitable ? "Contributor Stream" : "Subsidized Stream",
                              isProfitable
                                  ? "This stream generates more revenue than it spends. It is actively contributing to the overall health and profit of your business portfolio."
                                  : "This stream currently spends more than it earns. It is relying on your other streams (or personal capital) to stay afloat. Review its expenses to cure 'Subsidization Blindness'.",
                              isProfitable ? tfeGreen : Colors.red
                          ),
                          child: Icon(Icons.info_outline, size: 14, color: isProfitable ? tfeGreen : Colors.red),
                        )
                      ],
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              currency.format(amount),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isProfitable ? Colors.black : Colors.red),
            )
          ],
        ),
      ),
    );
  }
}