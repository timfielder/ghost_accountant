class WaterfallEngine {

  /// Calculates the split for a transaction based on the "Hybrid Split" rule.
  ///
  /// Rules [Source 40, 62]:
  /// 1. Deduct Fixed Overrides from Total.
  /// 2. Distribute remainder via Percentage Sliders.
  /// 3. Apply Integer/Cents rounding to the primary entity.

  static Map<String, int> calculateSplits({
    required int totalAmountCents,
    required Map<String, int> fixedOverrides, // entityId : amountCents
    required Map<String, double> percentageSliders, // entityId : 0.0 to 1.0
    required String primaryEntityId,
  }) {

    int remainingBalance = totalAmountCents;
    Map<String, int> finalSplits = {};

    // Step 1: Process Fixed Amounts first [Source 62]
    fixedOverrides.forEach((entityId, amount) {
      finalSplits[entityId] = amount;
      remainingBalance -= amount;
    });

    // Step 2: Process Percentages on the remainder [Source 62]
    int allocatedFromPercentage = 0;

    percentageSliders.forEach((entityId, percent) {
      // Calculate share of the *remaining* balance
      int share = (remainingBalance * percent).round();
      finalSplits[entityId] = (finalSplits[entityId] ?? 0) + share;
      allocatedFromPercentage += share;
    });

    // Step 3: Rounding Protection (Penny Remainder) [Source 40]
    // Any drift caused by .round() is added/subtracted from the Primary Entity
    int totalAllocated = 0;
    finalSplits.forEach((_, amount) => totalAllocated += amount);

    int remainder = totalAmountCents - totalAllocated;

    if (remainder != 0) {
      finalSplits[primaryEntityId] = (finalSplits[primaryEntityId] ?? 0) + remainder;
    }

    return finalSplits;
  }
}