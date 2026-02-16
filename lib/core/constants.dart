import 'package:flutter/material.dart';

class AppConstants {
  // The "Ghost" Taxonomy based on IRS Schedule C (User Provided)
  // This maps the UI directly to the tax form lines.
  static const List<Map<String, dynamic>> irsCategories = [
    {
      'name': 'Advertising',
      'icon': Icons.campaign,
      'desc': 'Website hosting, business cards, Google/Meta ads, SEO.'
    },
    {
      'name': 'Car & Truck',
      'icon': Icons.directions_car,
      'desc': 'Gasoline, oil, repairs, or standard mileage (70¢/mile in 2025).'
    },
    {
      'name': 'Commissions',
      'icon': Icons.percent,
      'desc': 'Affiliate payouts, referral fees, marketplace fees (Etsy/Amazon).'
    },
    {
      'name': 'Contract Labor',
      'icon': Icons.engineering,
      'desc': 'Payments to freelancers/1099 contractors.'
    },
    {
      'name': 'Depreciation',
      'icon': Icons.camera_alt,
      'desc': 'Section 179 equipment (Computers, cameras, machinery).'
    },
    {
      'name': 'Insurance',
      'icon': Icons.security,
      'desc': 'Liability, professional (E&O), or property insurance.'
    },
    {
      'name': 'Interest',
      'icon': Icons.credit_card,
      'desc': 'Business credit card interest and business loan interest.'
    },
    {
      'name': 'Legal/Professional',
      'icon': Icons.gavel,
      'desc': 'Attorneys, CPAs, or bookkeeping software.'
    },
    {
      'name': 'Office Expenses',
      'icon': Icons.print,
      'desc': 'Software subscriptions, small tools, postage, stationery.'
    },
    {
      'name': 'Rent',
      'icon': Icons.store,
      'desc': 'Coworking spaces or storage units.'
    },
    {
      'name': 'Supplies',
      'icon': Icons.inventory_2,
      'desc': 'Physical materials used to create products (not for office use).'
    },
    {
      'name': 'Taxes/Licenses',
      'icon': Icons.badge,
      'desc': 'LLC filing fees, business licenses, professional permits.'
    },
    {
      'name': 'Travel',
      'icon': Icons.flight,
      'desc': 'Airfare, hotels, Uber/Lyft (excluding meals).'
    },
    {
      'name': 'Meals',
      'icon': Icons.restaurant,
      'desc': 'Generally 50% deductible business meals.'
    },
    {
      'name': 'Utilities',
      'icon': Icons.lightbulb,
      'desc': 'Phone, internet, and electricity (if outside the home).'
    },
  ];
}