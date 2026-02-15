import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';
import '../data/models/entity_model.dart';

// The "Brain" that manages the state of the app
class TransactionProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _queue = [];
  List<Entity> _entities = [];

  List<Map<String, dynamic>> get queue => _queue;
  List<Entity> get entities => _entities;

  // 1. Load Data
  Future<void> loadInitialData(String userId) async {
    final db = await dbHelper.database;

    // Load Entities
    final entityMaps = await db.query('entities', where: 'user_id = ?', whereArgs: [userId]);
    _entities = entityMaps.map((e) => Entity.fromMap(e)).toList();

    await _refreshQueue();
  }

  // 2. The "Seed" Function (Generates Test Data)
  Future<void> seedDatabase() async {
    final db = await dbHelper.database;

    // Clear existing to avoid duplicates for testing
    await db.delete('transactions');

    // Insert "Ghost" Scenarios
    // Scenario 1: Tier 1 Match (Software)
    await db.insert('transactions', {
      'transaction_id': 'tx_001',
      'account_id': 'acct_1',
      'amount_cents': 2900, // $29.00
      'merchant_name': 'Adobe Creative Cloud',
      'date': DateTime.now().toIso8601String(),
      'status': 'PENDING',
    });

    // Scenario 2: Tier 3 Ambiguous (The Amazon Loop)
    await db.insert('transactions', {
      'transaction_id': 'tx_002',
      'account_id': 'acct_1',
      'amount_cents': 14250, // $142.50
      'merchant_name': 'AMZN Mktp US',
      'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'status': 'PENDING',
    });

    // Scenario 3: Coffee (Likely Personal)
    await db.insert('transactions', {
      'transaction_id': 'tx_003',
      'account_id': 'acct_1',
      'amount_cents': 650, // $6.50
      'merchant_name': 'Starbucks #4922',
      'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'status': 'PENDING',
    });

    await _refreshQueue();
  }

  // Helper to reload queue from DB
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

  // 3. Swipe Right (Business - 100% to Primary)
  Future<void> swipeRight(String transactionId, Entity targetEntity) async {
    final amount = await _getTransactionAmount(transactionId);
    await finalizeSplit(transactionId, {targetEntity.id: amount});
  }

  // 4. Finalize Logic
  Future<void> finalizeSplit(String transactionId, Map<String, int> splits) async {
    final db = await dbHelper.database;

    for (var entry in splits.entries) {
      await db.insert('splits', {
        'split_id': DateTime.now().millisecondsSinceEpoch.toString() + entry.key,
        'transaction_id': transactionId,
        'entity_id': entry.key,
        'amount_cents': entry.value,
        'logic_type': splits.length > 1 ? 'WATERFALL' : 'DIRECT',
      });
    }

    await db.update(
      'transactions',
      {'status': 'FINALIZED'},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    _queue.removeWhere((t) => t['transaction_id'] == transactionId);
    notifyListeners();
  }

  Future<int> _getTransactionAmount(String transactionId) async {
    // If queue is empty (swiped last card), fetch from DB or handle error
    if (_queue.any((t) => t['transaction_id'] == transactionId)) {
      final tx = _queue.firstWhere((t) => t['transaction_id'] == transactionId);
      return tx['amount_cents'] as int;
    }
    // Fallback if looking up a transaction that just left the queue
    final db = await dbHelper.database;
    final result = await db.query('transactions', where: 'transaction_id = ?', whereArgs: [transactionId]);
    return result.first['amount_cents'] as int;
  }
}