import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart'; // Required for currency formatting
import '../data/database/database_helper.dart';
import '../data/models/entity_model.dart';

class TransactionProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _queue = [];
  List<Entity> _entities = [];

  List<Map<String, dynamic>> get queue => _queue;
  List<Entity> get entities => _entities;

  // 1. Load Initial Data
  Future<void> loadInitialData(String userId) async {
    final db = await dbHelper.database;
    final entityMaps = await db.query('entities', where: 'user_id = ?', whereArgs: [userId]);
    _entities = entityMaps.map((e) => Entity.fromMap(e)).toList();
    await _refreshQueue();
  }

  // 2. Seed Test Data (Reset)
  Future<void> seedDatabase() async {
    final db = await dbHelper.database;
    await db.delete('transactions');
    await db.delete('splits');
    _fireDrillIndex = 0;
    await _refreshQueue();
  }

  // 3. Helper: Refresh Queue
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

  // 4. Swipe Right (Backward Compatibility Wrapper)
  Future<void> swipeRight(String transactionId, Entity targetEntity, {String category = 'Uncategorized'}) async {
    final amount = await _getTransactionAmount(transactionId);
    await finalizeSplit(
        transactionId: transactionId,
        splitRows: [
          {'entityId': targetEntity.id, 'amount': amount, 'category': category}
        ],
        saveAsRule: false
    );
  }

  // 5. FINALIZE LOGIC (Updated to Fix Persistence Bug)
  Future<void> finalizeSplit({
    required String transactionId,
    required List<Map<String, dynamic>> splitRows,
    bool saveAsRule = false
  }) async {
    final db = await dbHelper.database;

    // A. Insert Splits
    for (var row in splitRows) {
      await db.insert('splits', {
        'split_id': DateTime.now().millisecondsSinceEpoch.toString() + '_' + row['entityId'],
        'transaction_id': transactionId,
        'entity_id': row['entityId'],
        'amount_cents': row['amount'],
        'category': row['category'],
        'logic_type': splitRows.length > 1 ? 'WATERFALL' : 'DIRECT',
      });
    }

    // B. Mark Finalized (This removes it from the 'PENDING' query)
    await db.update('transactions', {'status': 'FINALIZED'}, where: 'transaction_id = ?', whereArgs: [transactionId]);

    // C. Force Refresh
    // Instead of manually removing it from the local list, we re-query the DB.
    // This guarantees the UI matches the Database state.
    await _refreshQueue();
  }

  // 6. FIRE DRILL CYCLE (Fixes the $2.00 Format)
  int _fireDrillIndex = 0;

  Future<void> triggerFireDrill(Function(String title, String body, String payload) onNotify) async {
    final db = await dbHelper.database;
    final newTxId = 'tx_notify_${DateTime.now().millisecondsSinceEpoch}';

    final scenarios = [
      {
        'merchant': 'Facebook Advertisement',
        'amount': 200, // $2.00
        'desc': 'Facebook Ads'
      },
      {
        'merchant': '7-Eleven',
        'amount': 4523, // $45.23
        'desc': 'Gas or Groceries?'
      },
      {
        'merchant': 'AMZN Mktp US',
        'amount': 19200, // $192.00
        'desc': 'Amazon (Needs Split)'
      },
      {
        'merchant': 'Fiverr',
        'amount': 15465, // $154.65
        'desc': 'Fiverr (Gig Revenue)'
      }
    ];

    final currentScenario = scenarios[_fireDrillIndex % scenarios.length];
    _fireDrillIndex++;

    await db.insert('transactions', {
      'transaction_id': newTxId,
      'account_id': 'acct_1',
      'amount_cents': currentScenario['amount'],
      'merchant_name': currentScenario['merchant'],
      'date': DateTime.now().toIso8601String(),
      'status': 'PENDING',
    });

    await _refreshQueue();

    // FORMATTING FIX: Ensure 2 decimal places ($2.00)
    final double amount = (currentScenario['amount'] as int) / 100.0;
    final formattedAmount = NumberFormat.simpleCurrency().format(amount);

    onNotify(
        "New Transaction",
        "$formattedAmount at ${currentScenario['merchant']}",
        newTxId
    );
  }

  // Helper
  Future<int> _getTransactionAmount(String transactionId) async {
    if (_queue.any((t) => t['transaction_id'] == transactionId)) {
      final tx = _queue.firstWhere((t) => t['transaction_id'] == transactionId);
      return tx['amount_cents'] as int;
    }
    final db = await dbHelper.database;
    final result = await db.query('transactions', where: 'transaction_id = ?', whereArgs: [transactionId]);
    return result.first['amount_cents'] as int;
  }
}