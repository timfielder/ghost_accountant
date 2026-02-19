import 'package:flutter/material.dart';

class AppConstants {

  // 1. INCOME (Money In)
  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Sales Revenue', 'icon': Icons.attach_money, 'desc': 'Income from services or products (IRS Line 1).'},
    {'name': 'Returns & Allowances', 'icon': Icons.replay, 'desc': 'Refunds given to customers (IRS Line 2).'},
    {'name': 'Other Income', 'icon': Icons.savings, 'desc': 'Interest, grants, awards (IRS Line 6).'},
    {'name': 'Credit', 'icon': Icons.arrow_circle_down, 'desc': 'General refunds or rewards.'}
  ];

  // 2. EXPENSE (Money Out)
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Advertising', 'icon': Icons.campaign, 'desc': 'Ads, hosting, promo (IRS Line 8).'},
    {'name': 'Contract Labor', 'icon': Icons.engineering, 'desc': '1099 Contractors (IRS Line 11).'},
    {'name': 'Legal & Professional', 'icon': Icons.gavel, 'desc': 'CPA, Lawyers (IRS Line 17).'},
    {'name': 'Office Expenses', 'icon': Icons.print, 'desc': 'Supplies under \$2.5k (IRS Line 18).'},
    {'name': 'Rent or Lease', 'icon': Icons.store, 'desc': 'Business property/machinery (IRS Line 20).'},
    {'name': 'Repairs & Maintenance', 'icon': Icons.build, 'desc': 'Incidental repairs (IRS Line 21).'},
    {'name': 'Supplies', 'icon': Icons.inventory_2, 'desc': 'Materials for jobs (IRS Line 22).'},
    {'name': 'Taxes & Licenses', 'icon': Icons.badge, 'desc': 'State tax, LLC fees (IRS Line 23).'},
    {'name': 'Travel', 'icon': Icons.flight, 'desc': 'Business travel (IRS Line 24a).'},
    {'name': 'Meals', 'icon': Icons.restaurant, 'desc': 'Client meals - 50% (IRS Line 24b).'},
    {'name': 'Utilities', 'icon': Icons.lightbulb, 'desc': 'Power/Internet (IRS Line 25).'},
    {'name': 'Software Subscriptions', 'icon': Icons.cloud_download, 'desc': 'SaaS tools (Adobe, AWS).'},
    {'name': 'Education & Training', 'icon': Icons.school, 'desc': 'Courses and seminars.'},
    {'name': 'Bank Charges & Interest', 'icon': Icons.account_balance, 'desc': 'Fees and interest.'}
  ];

  // 3. TRANSFERS (Internal Movement)
  static const List<Map<String, dynamic>> transferIn = [
    {'name': 'Transfer from Bank', 'icon': Icons.arrow_downward, 'desc': 'Money entering from another internal account.'},
    {'name': 'Owner\'s Contribution', 'icon': Icons.person_add, 'desc': 'Personal money put into the business.'}
  ];

  static const List<Map<String, dynamic>> transferOut = [
    {'name': 'Transfer to Bank or Credit Card', 'icon': Icons.arrow_outward, 'desc': 'Money leaving to pay another internal account.'},
    {'name': 'Owner\'s Draw', 'icon': Icons.person_remove, 'desc': 'Money taken out for personal use.'}
  ];

  // --- COMPATIBILITY GETTERS ---

  // FIX: This combines In/Out so the PnL Screen can read them all at once
  static List<Map<String, dynamic>> get transferCategories => [
    ...transferIn,
    ...transferOut
  ];

  // For Debits (Money leaving account) - Used by Triage Logic
  static List<Map<String, dynamic>> get debitCategories => [
    ...expenseCategories,
    ...transferOut
  ];

  // For Credits (Money entering account) - Used by Triage Logic
  static List<Map<String, dynamic>> get creditCategories => [
    ...incomeCategories,
    ...transferIn
  ];

  // Fallback (All)
  static List<Map<String, dynamic>> get allCategories => [
    ...incomeCategories,
    ...expenseCategories,
    ...transferIn,
    ...transferOut
  ];
}