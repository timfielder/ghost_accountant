import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_accountant/logic/waterfall_engine.dart';

void main() {
  group('Waterfall Logic - Zero Math Policy', () {

    // Test 1: The "Penny Perfect" Split [Source 40]
    // $100.00 split 3 ways (33.333...%)
    // Computers usually fail this. Ours must not.
    test('Handles repeating decimal rounding (The Penny Problem)', () {
      const totalAmount = 10000; // $100.00
      const primaryEntity = 'primary_llc';

      final result = WaterfallEngine.calculateSplits(
        totalAmountCents: totalAmount,
        fixedOverrides: {}, // No fixed amounts
        percentageSliders: {
          'primary_llc': 0.33333, // ~33%
          'consulting': 0.33333,
          'maker_shop': 0.33333,
        },
        primaryEntityId: primaryEntity,
      );

      // Verify the sum equals EXACTLY $100.00
      int totalAllocated = result.values.reduce((a, b) => a + b);
      expect(totalAllocated, totalAmount);

      // Verify the Primary Entity caught the extra penny
      // 3333 + 3333 + 3333 = 9999. Primary should have 3334.
      expect(result['primary_llc'], 3334);
    });

    // Test 2: The "Hybrid Split" [Source 60]
    // $100.00 Total.
    // Rule: $40 Fixed to Entity A.
    // Remaining $60 split 50/50 between B and C.
    test('Calculates Fixed Amount FIRST, then Percentages', () {
      const totalAmount = 10000; // $100.00
      const primaryEntity = 'entity_B';

      final result = WaterfallEngine.calculateSplits(
        totalAmountCents: totalAmount,
        fixedOverrides: {
          'entity_A': 4000, // $40.00 Fixed
        },
        percentageSliders: {
          'entity_B': 0.5, // 50% of remainder
          'entity_C': 0.5, // 50% of remainder
        },
        primaryEntityId: primaryEntity,
      );

      // Entity A should be exactly 4000
      expect(result['entity_A'], 4000);

      // Remaining is 6000. 50% of 6000 is 3000.
      expect(result['entity_B'], 3000);
      expect(result['entity_C'], 3000);

      // Total must be 10000
      expect(result.values.reduce((a, b) => a + b), 10000);
    });
  });
}