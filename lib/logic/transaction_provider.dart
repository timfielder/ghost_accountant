import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/entity_model.dart';
import 'export_service.dart';

class TransactionProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _queue = [];
  List<Entity> _entities = [];

  // DRAFT STATE MEMORY
  Map<String, Map<String, dynamic>> triageDrafts = {};

  bool useSmartMatch = true;

  List<Map<String, dynamic>> get queue => _queue;
  List<Entity> get entities => _entities;

  Future<void> loadInitialData(String userId) async {
    final db = await dbHelper.database;

    // Ensure Schema Integrity
    try { await db.execute("ALTER TABLE transactions ADD COLUMN notes TEXT"); } catch (_) {}
    try { await db.execute("ALTER TABLE splits ADD COLUMN memo TEXT"); } catch (_) {}

    final entityMaps = await db.query('entities', where: 'user_id = ?', whereArgs: [userId]);
    _entities = entityMaps.map((e) => Entity.fromMap(e)).toList();
    await _refreshQueue();
  }

  void toggleSmartMatch(bool value) {
    useSmartMatch = value;
    notifyListeners();
  }

  void saveDraft(String txId, {String? entityId, String? category, String? note}) {
    if (!triageDrafts.containsKey(txId)) triageDrafts[txId] = {};
    if (entityId != null) triageDrafts[txId]!['entityId'] = entityId;
    if (category != null) triageDrafts[txId]!['category'] = category;
    if (note != null) triageDrafts[txId]!['note'] = note;
  }

  void clearDraft(String txId) {
    triageDrafts.remove(txId);
  }

  // --- ENTITY & ACCOUNT MANAGEMENT ---

  Future<void> updateEntity(String entityId, String newName) async {
    final db = await dbHelper.database;
    await db.update('entities', {'entity_name': newName}, where: 'entity_id = ?', whereArgs: [entityId]);
    await loadInitialData('user_01');
  }

  Future<void> updateAccountNameOnly(String accountId, String newName) async {
    final db = await dbHelper.database;
    await db.update('accounts', {'institution_name': newName}, where: 'account_id = ?', whereArgs: [accountId]);
    notifyListeners();
  }

  Future<void> updateAccountToTargetBalance(String accountId, String newName, double targetCurrentBalance) async {
    final db = await dbHelper.database;
    final txRes = await db.rawQuery('SELECT SUM(amount_cents) as total FROM transactions WHERE account_id = ?', [accountId]);
    int netFlow = (txRes.first['total'] as int?) ?? 0;
    int targetCents = (targetCurrentBalance * 100).round();
    int newStartingBalance = targetCents - netFlow;

    await db.update('accounts', {'institution_name': newName, 'starting_balance_cents': newStartingBalance}, where: 'account_id = ?', whereArgs: [accountId]);
    notifyListeners();
  }

  Future<void> reconcileBalance(String accountId, String accountName, double targetBalance, String justificationNote) async {
    final db = await dbHelper.database;
    await db.update('accounts', {'institution_name': accountName}, where: 'account_id = ?', whereArgs: [accountId]);

    final currentBal = await getCalculatedBalance(accountId);
    final diff = targetBalance - currentBal;
    final int diffCents = (diff * 100).round();

    if (diffCents == 0) { notifyListeners(); return; }

    final String type = diffCents > 0 ? "Credit" : "Debit";
    final String fullNote = justificationNote.isEmpty ? "Manual Adjustment" : justificationNote;

    await db.insert('transactions', {
      'transaction_id': 'adj_${DateTime.now().millisecondsSinceEpoch}',
      'account_id': accountId,
      'amount_cents': diffCents,
      'merchant_name': "Manual Adjustment ($type)",
      'date': DateTime.now().toIso8601String(),
      'status': 'FINALIZED',
      'notes': fullNote
    });
    notifyListeners();
  }

  Future<double> getCalculatedBalance(String accountId) async {
    final db = await dbHelper.database;
    final acctRes = await db.query('accounts', where: 'account_id = ?', whereArgs: [accountId]);
    if (acctRes.isEmpty) return 0.0;

    int starting = (acctRes.first['starting_balance_cents'] as int?) ?? 0;
    final txRes = await db.rawQuery('SELECT SUM(amount_cents) as total FROM transactions WHERE account_id = ?', [accountId]);
    int netFlow = (txRes.first['total'] as int?) ?? 0;

    return (starting + netFlow) / 100.0;
  }

  Future<void> resetDatabase() async {
    final db = await dbHelper.database;
    await db.delete('entities');
    await db.delete('transactions');
    await db.delete('splits');
    await db.delete('accounts');
    _entities = [];
    _queue = [];
    triageDrafts.clear();
    notifyListeners();
  }

  Future<bool> deleteEntity(String entityId) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM splits WHERE entity_id = ?', [entityId]));
    if (count != null && count > 0) return false;

    await db.delete('entities', where: 'entity_id = ?', whereArgs: [entityId]);
    await loadInitialData('user_01');
    return true;
  }

  Future<bool> deleteAccount(String accountId) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions WHERE account_id = ?', [accountId]));
    if (count != null && count > 0) return false;

    await db.delete('accounts', where: 'account_id = ?', whereArgs: [accountId]);
    notifyListeners();
    return true;
  }

  Future<void> startNewYearProtocol(Rect shareOrigin) async {
    final db = await dbHelper.database;
    try { await ExportService.generateAndShareCsv(shareOrigin); } catch (e) { print("Backup warning: $e"); }

    final accounts = await db.query('accounts');
    for (var acct in accounts) {
      String acctId = acct['account_id'] as String;
      int starting = (acct['starting_balance_cents'] as int?) ?? 0;
      final result = await db.rawQuery('SELECT SUM(amount_cents) as total FROM transactions WHERE account_id = ?', [acctId]);
      int netFlow = (result.first['total'] as int?) ?? 0;
      await db.update('accounts', {'starting_balance_cents': starting + netFlow}, where: 'account_id = ?', whereArgs: [acctId]);
    }

    await db.delete('splits');
    await db.delete('transactions');
    triageDrafts.clear();
    await _refreshQueue();
    notifyListeners();
  }

  Future<void> addEntity(String name, {required bool isPrimary}) async {
    final db = await dbHelper.database;
    final id = 'ent_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('entities', {'entity_id': id, 'user_id': 'user_01', 'entity_name': name, 'is_primary': isPrimary ? 1 : 0});
    await loadInitialData('user_01');
  }

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

  Future<void> _refreshQueue() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT t.*, a.institution_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.account_id
      WHERE t.status = 'PENDING'
      ORDER BY t.date DESC
    ''');
    _queue = results;
    notifyListeners();
  }

  // --- TRIAGE ACTIONS ---

  Future<void> finalizeSplit({required String transactionId, required List<Map<String, dynamic>> splitRows, String? note}) async {
    final db = await dbHelper.database;

    for (var row in splitRows) {
      await db.insert('splits', {
        'split_id': '${DateTime.now().millisecondsSinceEpoch}_${row['entityId']}_${row.hashCode}',
        'transaction_id': transactionId,
        'entity_id': row['entityId'],
        'amount_cents': row['amount'],
        'category': row['category'],
        'logic_type': splitRows.length > 1 ? 'WATERFALL' : 'DIRECT',
        'memo': row['memo']
      });
    }

    Map<String, dynamic> updateData = {'status': 'FINALIZED'};
    if (note != null && note.isNotEmpty) updateData['notes'] = note;

    await db.update('transactions', updateData, where: 'transaction_id = ?', whereArgs: [transactionId]);
    clearDraft(transactionId);
    await _refreshQueue();
  }

  // --- SMART MATCH ENGINE (3-Time Rule) ---

  Future<List<Map<String, dynamic>>?> getSmartMatchTemplate(String merchantName) async {
    if (!useSmartMatch) return null;
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> lastTxns = await db.query(
        'transactions',
        columns: ['transaction_id', 'amount_cents'],
        where: 'merchant_name = ? AND status = ?',
        whereArgs: [merchantName, 'FINALIZED'],
        orderBy: 'date DESC',
        limit: 3
    );

    if (lastTxns.length < 3) return null;

    List<List<Map<String, dynamic>>> historySplits = [];

    for (var tx in lastTxns) {
      final splits = await db.query(
          'splits',
          columns: ['entity_id', 'category', 'amount_cents'],
          where: 'transaction_id = ?',
          whereArgs: [tx['transaction_id']]
      );
      historySplits.add(splits);
    }

    // FIXED: Use the first history item as the template to compare against others
    final template = historySplits.first;

    for (int i = 1; i < historySplits.length; i++) {
      if (!_areSplitsStructurallyEqual(template, historySplits[i])) {
        return null; // Pattern Broken
      }
    }

    return template; // FIXED: Returns List<Map>, not List<List>
  }

  bool _areSplitsStructurallyEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;

    final setA = a.map((s) => "${s['entity_id']}|${s['category']}").toSet();
    final setB = b.map((s) => "${s['entity_id']}|${s['category']}").toSet();

    return setA.length == setB.length && setA.containsAll(setB);
  }

  // --- REPORTING METRICS ---

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await dbHelper.database;
    final splits = await db.rawQuery('SELECT * FROM splits');
    final entities = await db.query('entities');
    final accounts = await db.query('accounts');

    double totalNet = 0;
    List<Map<String, dynamic>> streamLeaderboard = [];
    List<Map<String, dynamic>> accountLeaderboard = [];

    for (var entity in entities) {
      String id = entity['entity_id'] as String;
      String name = entity['entity_name'] as String;
      double entityNet = 0;
      for (var s in splits) {
        if (s['entity_id'] == id) entityNet += (s['amount_cents'] as int);
      }
      streamLeaderboard.add({'id': id, 'name': name, 'net': entityNet / 100});
      totalNet += entityNet;
    }

    final txs = await db.query('transactions');
    for (var acct in accounts) {
      String acctId = acct['account_id'] as String;
      String name = acct['institution_name'] as String;
      int starting = (acct['starting_balance_cents'] as int?) ?? 0;
      double currentBalance = starting.toDouble();
      for (var tx in txs) {
        if (tx['account_id'] == acctId) currentBalance += (tx['amount_cents'] as int);
      }
      accountLeaderboard.add({'id': acctId, 'name': name, 'net': currentBalance / 100});
    }

    return {'netProfit': totalNet / 100, 'streamLeaderboard': streamLeaderboard, 'accountLeaderboard': accountLeaderboard};
  }

  Future<Map<String, dynamic>> getEntityPnL(String entityId) async {
    final db = await dbHelper.database;
    final splits = await db.rawQuery('SELECT * FROM splits WHERE entity_id = ?', [entityId]);
    return _calculatePnLFromSplits(splits);
  }

  Future<Map<String, dynamic>> getAccountPnL(String accountId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('SELECT amount_cents FROM transactions WHERE account_id = ?', [accountId]);

    double netIncome = 0;
    Map<String, double> income = {};
    Map<String, double> expenses = {};
    Map<String, double> transfers = {};
    double totalIn = 0;
    double totalOut = 0;

    for (var row in results) {
      double amount = (row['amount_cents'] as int) / 100.0;
      netIncome += amount;
      if (amount >= 0) {
        totalIn += amount;
      } else {
        totalOut += amount.abs();
      }
    }
    income['Deposits / Credits'] = totalIn;
    expenses['Withdrawals / Debits'] = totalOut;
    return {'netIncome': netIncome, 'income': income, 'expenses': expenses, 'transfers': transfers};
  }

  Map<String, dynamic> _calculatePnLFromSplits(List<Map<String, Object?>> rows) {
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
    return {'netIncome': netIncome, 'income': income, 'expenses': expenses, 'transfers': transfers};
  }

  String _getCategoryType(String category) {
    if (category.contains('Revenue') || category.contains('Income') || category == 'Credit' || category.contains('Contribution')) return 'INCOME';
    if (category.contains('Transfer') || category.contains('Draw')) return 'TRANSFER';
    return 'EXPENSE';
  }
}