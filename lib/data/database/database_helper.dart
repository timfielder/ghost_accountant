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

    // 2. Entities Table (The "Sub-Brands") [Source 59]
    await db.execute('''
      CREATE TABLE entities (
        entity_id TEXT PRIMARY KEY,
        user_id TEXT,
        entity_name TEXT,
        is_primary INTEGER, -- 1 for true, 0 for false
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // 3. Accounts Table (Linked via Teller) [Source 59]
    await db.execute('''
      CREATE TABLE accounts (
        account_id TEXT PRIMARY KEY,
        user_id TEXT,
        teller_access_token TEXT, -- Stored securely
        institution_name TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // 4. Transactions Table (Raw Bank Data) [Source 34]
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        account_id TEXT,
        amount_cents INTEGER, -- CRITICAL: Integer Cent Protection [Source 40]
        merchant_name TEXT,
        date TEXT,
        status TEXT, -- PENDING, SUGGESTED, FINALIZED [Source 39]
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
      )
    ''');

    // 5. Splits Table (The Result of the Waterfall) [Source 59]
    await db.execute('''
      CREATE TABLE splits (
        split_id TEXT PRIMARY KEY,
        transaction_id TEXT,
        entity_id TEXT,
        amount_cents INTEGER,
        logic_type TEXT, -- 'FIXED' or 'PERCENT'
        FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id),
        FOREIGN KEY (entity_id) REFERENCES entities (entity_id)
      )
    ''');
  }
}