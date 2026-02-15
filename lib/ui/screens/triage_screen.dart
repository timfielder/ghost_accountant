import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../logic/transaction_provider.dart';
import '../widgets/triage_card.dart';

class TriageScreen extends StatelessWidget {
  const TriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Triage Mode"),
        centerTitle: true,
        actions: [
          // DEBUG BUTTON: Adds fake data so we can test
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            tooltip: "Inject Test Data",
            onPressed: () {
              context.read<TransactionProvider>().seedDatabase();
            },
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
                  const Text("All Caught Up! 🎉", style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  const Text("Tap the ⚡ icon above to simulate transactions.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header Stats
                Text(
                  "${provider.queue.length} Transactions Pending",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),

                // The Swipe Stack
                Expanded(
                  child: CardSwiper(
                    cardsCount: provider.queue.length,
                    controller: CardSwiperController(),

                    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                      return TriageCard(transaction: provider.queue[index]);
                    },

                    onSwipe: (previousIndex, currentIndex, direction) {
                      final tx = provider.queue[previousIndex];
                      final txId = tx['transaction_id'];

                      if (direction == CardSwiperDirection.right) {
                        // 1. Find Primary Entity
                        try {
                          final primary = provider.entities.firstWhere((e) => e.isPrimary);
                          provider.swipeRight(txId, primary);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Charged to ${primary.name}"), duration: const Duration(milliseconds: 500)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error: No Primary Entity Found")),
                          );
                        }
                      }
                      else if (direction == CardSwiperDirection.left) {
                        // Personal Logic (Just clear it for now)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Marked as Personal"), duration: Duration(milliseconds: 500)),
                        );
                      }
                      return true;
                    },
                  ),
                ),

                // The "Waterfall" Button placeholder
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open Waterfall Screen
                  },
                  icon: const Icon(Icons.water_drop, color: Colors.amber),
                  label: const Text("Split Transaction (Waterfall)"),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}