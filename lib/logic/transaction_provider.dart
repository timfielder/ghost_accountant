import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/entity_model.dart';

class TransactionProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _queue = [];
  List<Entity> _entities = [];

  List<Map<String, dynamic>> get queue => _queue;
  List<Entity> get entities => _entities;

  // --- 1. CORE METHODS ---

  Future<void> loadInitialData(String userId) async {
    final db = await dbHelper.database;
    final entityMaps = await db.query('entities', where: 'user_id = ?', whereArgs: [userId]);
    _entities = entityMaps.map((e) => Entity.fromMap(e)).toList();
    await _refreshQueue();
  }

  Future<void> resetDatabase() async {
    final db = await dbHelper.database;
    await db.delete('entities');
    await db.delete('transactions');
    await db.delete('splits');
    await db.delete('accounts'); // Ensure accounts are wiped too
    _entities = [];
    _queue = [];
    notifyListeners();
  }

  Future<void> addEntity(String name, {required bool isPrimary}) async {
    final db = await dbHelper.database;
    final id = 'ent_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('entities', {
      'entity_id': id,
      'user_id': 'user_01',
      'entity_name': name,
      'is_primary': isPrimary ? 1 : 0
    });

    await loadInitialData('user_01');
  }

  // UPDATED: Now accepts startingBalance
  Future<void> addAccount(String name, double startingBalance) async {
    final db = await dbHelper.database;
    final id = 'acct_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('accounts', {
      'account_id': id,
      'user_id': 'user_01',
      'institution_name': name,
      'teller_access_token': 'manual_entry',
      'starting_balance_cents': (startingBalance * 100).round(),
    });
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await dbHelper.database;
    return await db.query('accounts', where: 'user_id = ?', whereArgs: ['user_01']);
  }

  // --- 2. QUEUE MANAGEMENT ---

  Future<void> _refreshQueue() async {
    final db = await dbHelper.database;
    _queue = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'date DESC',
    );
    notifyListeners();
  }

  // --- 3. ACTIONS ---

  Future<void> finalizeSplit({required String transactionId, required List<Map<String, dynamic>> splitRows}) async {
    final db = await dbHelper.database;

    for (var row in splitRows) {
      await db.insert('splits', {
        'split_id': '${DateTime.now().millisecondsSinceEpoch}_${row['entityId']}',
        'transaction_id': transactionId,
        'entity_id': row['entityId'],
        'amount_cents': row['amount'],
        'category': row['category'],
        'logic_type': splitRows.length > 1 ? 'WATERFALL' : 'DIRECT',
      });
    }

    await db.update('transactions', {'status': 'FINALIZED'}, where: 'transaction_id = ?', whereArgs: [transactionId]);
    await _refreshQueue();
  }

  // --- 4. DASHBOARD METRICS ---

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await dbHelper.database;

    final splits = await db.rawQuery('SELECT * FROM splits');
    final entities = await db.query('entities');
    final accounts = await db.query('accounts');

    double totalNet = 0;
    List<Map<String, dynamic>> streamLeaderboard = [];
    List<Map<String, dynamic>> accountLeaderboard = [];

    // Streams
    for (var entity in entities) {
      String id = entity['entity_id'] as String;
      String name = entity['entity_name'] as String;
      double entityNet = 0;

      for (var s in splits) {
        if (s['entity_id'] == id) {
          entityNet += (s['amount_cents'] as int);
        }
      }

      streamLeaderboard.add({'id': id, 'name': name, 'net': entityNet / 100});
      totalNet += entityNet;
    }

    // Accounts (Calculated from Transactions + Starting Balance in a real app)
    final txs = await db.query('transactions');
    for (var acct in accounts) {
      String acctId = acct['account_id'] as String;
      String name = acct['institution_name'] as String;
      int starting = (acct['starting_balance_cents'] as int?) ?? 0;
      double currentBalance = starting.toDouble(); // Start with baseline

      for (var tx in txs) {
        if (tx['account_id'] == acctId) {
          currentBalance += (tx['amount_cents'] as int);
        }
      }

      accountLeaderboard.add({'id': acctId, 'name': name, 'net': currentBalance / 100});
    }

    return {
      'netProfit': totalNet / 100,
      'streamLeaderboard': streamLeaderboard,
      'accountLeaderboard': accountLeaderboard,
    };
  }

  // --- 5. P&L ENGINES ---

  Future<Map<String, dynamic>> getEntityPnL(String entityId) async {
    final db = await dbHelper.database;
    final splits = await db.rawQuery('SELECT * FROM splits WHERE entity_id = ?', [entityId]);
    return _calculatePnLFromRows(splits);
  }

  Future<Map<String, dynamic>> getAccountPnL(String accountId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('''
      SELECT s.category, s.amount_cents 
      FROM splits s
      JOIN transactions t ON s.transaction_id = t.transaction_id
      WHERE t.account_id = ?
    ''', [accountId]);
    return _calculatePnLFromRows(results);
  }

  Map<String, dynamic> _calculatePnLFromRows(List<Map<String, Object?>> rows) {
    Map<String, double> income = {};
    Map<String, double> expenses = {};
    Map<String, double> transfers = {};
    double netIncome = 0;

    for (var row in rows) {
      String category = row['category'] as String;
      double amount = (row['amount_cents'] as int) / 100.0;
      String type = _getCategoryType(category);

      if (type == 'INCOME') {
        income[category] = (income[category] ?? 0) + amount;
        netIncome += amount;
      } else if (type == 'EXPENSE') {
        expenses[category] = (expenses[category] ?? 0) + amount;
        netIncome -= amount;
      } else {
        transfers[category] = (transfers[category] ?? 0) + amount;
      }
    }

    return {
      'netIncome': netIncome,
      'income': income,
      'expenses': expenses,
      'transfers': transfers
    };
  }

  String _getCategoryType(String category) {
    if (category.contains('Revenue') || category.contains('Income') || category == 'Credit') return 'INCOME';
    if (category.contains('Transfer') || category.contains('Owner')) return 'TRANSFER';
    return 'EXPENSE';
  }
}