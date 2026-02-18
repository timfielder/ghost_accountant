import 'package:flutter/material.dart';

class AppConstants {
  // IRS SCHEDULE C - INCOME CATEGORIES [Source 4]
  static const List<Map<String, dynamic>> incomeCategories = [
    {
      'name': 'Sales Revenue',
      'icon': Icons.attach_money,
      'desc': 'Income from services performed or products sold (e.g., Fiverr, Etsy, Consulting Fees). IRS Line 1.'
    },
    {
      'name': 'Returns & Allowances',
      'icon': Icons.replay,
      'desc': 'Refunds you gave to customers or discounts taken by them. IRS Line 2.'
    },
    {
      'name': 'Other Income',
      'icon': Icons.savings,
      'desc': 'Interest, grants, or awards not related to main services. IRS Line 6.'
    },
    {
      'name': 'Credit',
      'icon': Icons.arrow_circle_down,
      'desc': 'General credits, refunds, or rewards (e.g., Amazon Shop with Points).'
    }
  ];

  // IRS SCHEDULE C - EXPENSE CATEGORIES [Source 4, 84]
  static const List<Map<String, dynamic>> expenseCategories = [
    {
      'name': 'Advertising',
      'icon': Icons.campaign,
      'desc': 'Promotions, Facebook/Google Ads, website hosting, and business cards. IRS Line 8.'
    },
    {
      'name': 'Contract Labor',
      'icon': Icons.engineering,
      'desc': 'Payments to freelancers/independent contractors (1099 workers). NOT employees. IRS Line 11.'
    },
    {
      'name': 'Legal & Professional',
      'icon': Icons.gavel,
      'desc': 'Fees for lawyers, accountants, and tax preparers. IRS Line 17.'
    },
    {
      'name': 'Office Expenses',
      'icon': Icons.print,
      'desc': 'General office supplies, postage, software subscriptions, and small tools under \$2,500. IRS Line 18.'
    },
    {
      'name': 'Rent or Lease',
      'icon': Icons.store,
      'desc': 'Rent for business property (office/storage) or equipment machinery. IRS Line 20.'
    },
    {
      'name': 'Repairs & Maintenance',
      'icon': Icons.build,
      'desc': 'Incidental repairs to keep property in operating condition (not improvements). IRS Line 21.'
    },
    {
      'name': 'Supplies',
      'icon': Icons.inventory_2,
      'desc': 'Physical materials used to create products or provide services (not COGS). IRS Line 22.'
    },
    {
      'name': 'Taxes & Licenses',
      'icon': Icons.badge,
      'desc': 'State tax, business licenses, trademarks, and regulatory fees. IRS Line 23.'
    },
    {
      'name': 'Travel',
      'icon': Icons.flight,
      'desc': 'Lodging and transportation costs for business travel away from your tax home. IRS Line 24a.'
    },
    {
      'name': 'Meals',
      'icon': Icons.restaurant,
      'desc': 'Business meals with clients (50% deductible). IRS Line 24b.'
    },
    {
      'name': 'Utilities',
      'icon': Icons.lightbulb,
      'desc': 'Power, internet, and phone used strictly for business (if outside home). IRS Line 25.'
    },
    {
      'name': 'Software Subscriptions',
      'icon': Icons.cloud_download,
      'desc': 'SaaS tools (Adobe, Zoom, AWS) necessary for business operations. (Often grouped with Office Expense).'
    },
    {
      'name': 'Education & Training',
      'icon': Icons.school,
      'desc': 'Courses, seminars, and books related to maintaining professional skills.'
    },
    {
      'name': 'Bank Charges & Interest',
      'icon': Icons.account_balance,
      'desc': 'Service fees, overdraft fees, and credit card interest.'
    }
  ];

  // INTERNAL TRANSFERS [Source 2, 4]
  static const List<Map<String, dynamic>> transferCategories = [
    {
      'name': 'Transfer to Bank or Credit Card',
      'icon': Icons.arrow_outward, // FIXED: Replaced arrow_inward with standard icon
      'desc': 'Money leaving this account to pay another internal account (e.g., Checking -> Amex).'
    },
    {
      'name': 'Transfer from Bank',
      'icon': Icons.arrow_downward, // FIXED: Replaced arrow_inward
      'desc': 'Money entering this account from another internal account (e.g., Amex <- Checking).'
    },
    {
      'name': 'Owner\'s Draw',
      'icon': Icons.person_remove,
      'desc': 'Money taken out of the business for personal use. Not a tax deduction.'
    },
    {
      'name': 'Owner\'s Contribution',
      'icon': Icons.person_add,
      'desc': 'Personal money put into the business.'
    }
  ];

  // COMPATIBILITY GETTER: Fixes "Member not found: irsCategories"
  // Combines all lists so the dropdown works immediately.
  static List<Map<String, dynamic>> get irsCategories => [
    ...incomeCategories,
    ...expenseCategories,
    ...transferCategories
  ];

  // Helper alias for clarity in new code
  static List<Map<String, dynamic>> get allCategories => irsCategories;
}