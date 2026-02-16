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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Users Table [Source 59]
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        email TEXT,
        stripe_sub_status TEXT
      )
    ''');

    // 2. Entities Table [Source 59]
    await db.execute('''
      CREATE TABLE entities (
        entity_id TEXT PRIMARY KEY,
        user_id TEXT,
        entity_name TEXT,
        is_primary INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // 3. Accounts Table [Source 59]
    await db.execute('''
      CREATE TABLE accounts (
        account_id TEXT PRIMARY KEY,
        user_id TEXT,
        teller_access_token TEXT,
        institution_name TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // 4. Transactions Table [Source 34]
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        account_id TEXT,
        amount_cents INTEGER,
        merchant_name TEXT,
        date TEXT,
        status TEXT, -- PENDING, FINALIZED
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
      )
    ''');

    // 5. Splits Table (UPDATED: Added 'category' column) [Source 133]
    await db.execute('''
      CREATE TABLE splits (
        split_id TEXT PRIMARY KEY,
        transaction_id TEXT,
        entity_id TEXT,
        amount_cents INTEGER,
        category TEXT, -- THIS WAS MISSING
        logic_type TEXT, 
        FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id),
        FOREIGN KEY (entity_id) REFERENCES entities (entity_id)
      )
    ''');
  }
}