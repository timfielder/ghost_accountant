import 'package:flutter/material.dart';

class AppConstants {

  // 1. INCOME (Money In)
  static const List<Map<String, dynamic>> incomeCategories = [
    {
      'name': 'Sales Revenue',
      'icon': Icons.attach_money,
      'desc': 'Income from services or products (IRS Line 1).',
      'example': 'Consulting fees, product sales, Fiverr payouts.'
    },
    {
      'name': 'Returns & Allowances',
      'icon': Icons.replay,
      'desc': 'Refunds given to customers (IRS Line 2).',
      'example': 'Refunded course fees, returned merchandise.'
    },
    {
      'name': 'Other Income',
      'icon': Icons.savings,
      'desc': 'Interest, grants, awards (IRS Line 6).',
      'example': 'High-yield savings interest, business grants.'
    },
    {
      'name': 'Credit',
      'icon': Icons.arrow_circle_down,
      'desc': 'General refunds or rewards.',
      'example': 'Credit card cash back, vendor reimbursements.'
    }
  ];

  // 2. EXPENSE (Money Out) - Updated with Source 265 Definitions
  static const List<Map<String, dynamic>> expenseCategories = [
    {
      'name': 'Advertising',
      'icon': Icons.campaign,
      'desc': 'Costs to promote your business and build your brand (IRS Line 8).',
      'example': 'Google Ads, business cards, website hosting, sponsored posts.'
    },
    {
      'name': 'Contract Labor',
      'icon': Icons.engineering,
      'desc': 'Payments to independent contractors or freelancers (IRS Line 11).',
      'example': 'Freelance designers, virtual assistants, specialized technicians.'
    },
    {
      'name': 'Legal & Professional',
      'icon': Icons.gavel,
      'desc': 'Fees paid to professionals for business compliance (IRS Line 17).',
      'example': 'Accountant (CPA), lawyers, business consultants.'
    },
    {
      'name': 'Office Expenses',
      'icon': Icons.print,
      'desc': 'Day-to-day costs of running an office space (IRS Line 18).',
      'example': 'Shipping supplies, printer ink, small software (Zoom/Slack) under \$2.5k.'
    },
    {
      'name': 'Rent or Lease',
      'icon': Icons.store,
      'desc': 'Payments for machinery, vehicles, or office space (IRS Line 20).',
      'example': 'Co-working memberships, equipment rentals, warehouse lease.'
    },
    {
      'name': 'Repairs & Maintenance',
      'icon': Icons.build,
      'desc': 'Costs to keep equipment/property in working order (IRS Line 21).',
      'example': 'Laptop screen repair, HVAC servicing, equipment fixes.'
    },
    {
      'name': 'Supplies',
      'icon': Icons.inventory_2,
      'desc': 'Tangible items used to operate that aren\'t inventory (IRS Line 22).',
      'example': 'Cleaning supplies, lightbulbs, small tools < 1 year life.'
    },
    {
      'name': 'Taxes & Licenses',
      'icon': Icons.badge,
      'desc': 'State tax, LLC fees, and permits (IRS Line 23).',
      'example': 'Business licenses, LLC filing fees, employer payroll taxes.'
    },
    {
      'name': 'Travel',
      'icon': Icons.flight,
      'desc': 'Transportation/lodging away from "tax home" (IRS Line 24a).',
      'example': 'Airfare, hotels, Uber/Lyft to conferences.'
    },
    {
      'name': 'Meals',
      'icon': Icons.restaurant,
      'desc': 'Food/bev with business contacts or while traveling (IRS Line 24b).',
      'example': 'Client dinners, airport meals (50% deductible).'
    },
    {
      'name': 'Utilities',
      'icon': Icons.lightbulb,
      'desc': 'Recurring costs for basic services (IRS Line 25).',
      'example': 'Electricity, internet service, business phone line.'
    },
    {
      'name': 'Software Subscriptions',
      'icon': Icons.cloud_download,
      'desc': 'Recurring SaaS tools (IRS "Other Expenses").',
      'example': 'Adobe Creative Cloud, AWS, QuickBooks, BEAMS.'
    },
    {
      'name': 'Education & Training',
      'icon': Icons.school,
      'desc': 'Courses and seminars to maintain skills (IRS "Other Expenses").',
      'example': 'Online courses, trade seminars, masterminds.'
    },
    {
      'name': 'Bank Charges & Interest',
      'icon': Icons.account_balance,
      'desc': 'Fees and interest paid on business debts.',
      'example': 'Monthly service fees, loan interest, credit card interest.'
    },
    {
      'name': 'Other Expenses',
      'icon': Icons.receipt_long,
      'desc': 'Necessary costs that do not fit standard categories.',
      'example': 'Professional dues, trade journals, uniforms.'
    }
  ];

  // 3. TRANSFERS (Internal Movement)
  static const List<Map<String, dynamic>> transferIn = [
    {'name': 'Transfer from Bank', 'icon': Icons.arrow_downward, 'desc': 'Money entering from another internal account.', 'example': 'Payment from Checking to Credit Card.'},
    {'name': 'Owner\'s Contribution', 'icon': Icons.person_add, 'desc': 'Personal money put into the business.', 'example': 'Funding a new account from personal savings.'}
  ];

  static const List<Map<String, dynamic>> transferOut = [
    {'name': 'Transfer to Bank or Credit Card', 'icon': Icons.arrow_outward, 'desc': 'Money leaving to pay another internal account.', 'example': 'Paying off the Amex bill.'},
    {'name': 'Owner\'s Draw', 'icon': Icons.person_remove, 'desc': 'Money taken out for personal use.', 'example': 'Paying yourself your salary/draw.'}
  ];

  // --- COMPATIBILITY GETTERS ---
  static List<Map<String, dynamic>> get transferCategories => [...transferIn, ...transferOut];
  static List<Map<String, dynamic>> get debitCategories => [...expenseCategories, ...transferOut];
  static List<Map<String, dynamic>> get creditCategories => [...incomeCategories, ...transferIn];
  static List<Map<String, dynamic>> get allCategories => [...incomeCategories, ...expenseCategories, ...transferIn, ...transferOut];
}