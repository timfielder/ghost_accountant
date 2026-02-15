import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../data/models/entity_model.dart';
import 'waterfall_engine.dart';

// The "Brain" that manages the state of the app [Source 59]
class TransactionProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _queue = []; // The "Stack" of cards
  List<Entity> _entities = []; // The sub-brands available

  // Getters
  List<Map<String, dynamic>> get queue => _queue;
  List<Entity> get entities => _entities;

  // 1. Load Data (Simulating the App Start)
  Future<void> loadInitialData(String userId) async {
    final db = await dbHelper.database;

    // Load Entities
    final entityMaps = await db.query('entities', where: 'user_id = ?', whereArgs: [userId]);
    _entities = entityMaps.map((e) => Entity.fromMap(e)).toList();

    // Load Pending Transactions (The Triage Queue)
    // In a real app, this comes from Teller.io webhooks [Source 52]
    // For MVP, we will query the local DB for 'PENDING' status
    _queue = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'date DESC',
    );

    notifyListeners();
  }

  // 2. The "Swipe Right" Logic (100% Attribution)
  Future<void> swipeRight(String transactionId, Entity targetEntity) async {
    // 100% goes to one entity
    await finalizeSplit(transactionId, {
      targetEntity.id: await _getTransactionAmount(transactionId)
    });
  }

  // 3. The "Waterfall" Logic (Complex Split)
  Future<void> processWaterfallSplit(String transactionId, Map<String, int> finalSplits) async {
    await finalizeSplit(transactionId, finalSplits);
  }

  // Helper: Commit to Database
  Future<void> finalizeSplit(String transactionId, Map<String, int> splits) async {
    final db = await dbHelper.database;

    // A. Save the Splits [Source 12]
    for (var entry in splits.entries) {
      await db.insert('splits', {
        'split_id': DateTime.now().millisecondsSinceEpoch.toString() + entry.key, // Simple ID
        'transaction_id': transactionId,
        'entity_id': entry.key,
        'amount_cents': entry.value,
        'logic_type': splits.length > 1 ? 'WATERFALL' : 'DIRECT',
      });
    }

    // B. Update Transaction Status to FINALIZED [Source 59]
    await db.update(
      'transactions',
      {'status': 'FINALIZED'},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    // C. Remove from Queue (UI Update)
    _queue.removeWhere((t) => t['transaction_id'] == transactionId);
    notifyListeners();
  }

  Future<int> _getTransactionAmount(String transactionId) async {
    final tx = _queue.firstWhere((t) => t['transaction_id'] == transactionId);
    return tx['amount_cents'] as int;
  }
}