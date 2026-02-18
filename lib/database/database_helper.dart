import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ghost_accountant.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Increment version if you ever need to migrate without deleting,
    // but for now we are doing a Hard Reset.
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        email TEXT,
        stripe_sub_status TEXT
      )
    ''');

    // 2. Entities Table
    await db.execute('''
      CREATE TABLE entities (
        entity_id TEXT PRIMARY KEY,
        user_id TEXT,
        entity_name TEXT,
        is_primary INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // 3. Accounts Table (UPDATED: Added starting_balance_cents)
    await db.execute('''
      CREATE TABLE accounts (
        account_id TEXT PRIMARY KEY,
        user_id TEXT,
        teller_access_token TEXT,
        institution_name TEXT,
        starting_balance_cents INTEGER DEFAULT 0, 
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // 4. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        account_id TEXT,
        amount_cents INTEGER,
        merchant_name TEXT,
        date TEXT,
        status TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
      )
    ''');

    // 5. Splits Table
    await db.execute('''
      CREATE TABLE splits (
        split_id TEXT PRIMARY KEY,
        transaction_id TEXT,
        entity_id TEXT,
        amount_cents INTEGER,
        category TEXT,
        logic_type TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id),
        FOREIGN KEY (entity_id) REFERENCES entities (entity_id)
      )
    ''');
  }
}