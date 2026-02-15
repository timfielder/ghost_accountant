import '../database/database_helper.dart';
import '../models/entity_model.dart'; // We will create this next
import 'package:sqflite/sqflite.dart';

class EntityRepository {
  final dbHelper = DatabaseHelper.instance;

  /// createDefaultEntities is run when the user first opens the app.
  /// It establishes the "Parent" and "Child" structure [Source 59].
  Future<void> createDefaultEntities(String userId) async {
    final db = await dbHelper.database;

    // Check if entities already exist
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM entities WHERE user_id = ?', [userId])
    );

    if (count == 0) {
      // Create the default "Umbrella" and common Solopreneur buckets [Source 31]
      await db.insert('entities', {
        'entity_id': '${userId}_primary',
        'user_id': userId,
        'entity_name': 'Primary/Umbrella LLC',
        'is_primary': 1, // This entity catches the penny rounding [Source 40]
      });

      await db.insert('entities', {
        'entity_id': '${userId}_consulting',
        'user_id': userId,
        'entity_name': 'Consulting Services',
        'is_primary': 0,
      });

      await db.insert('entities', {
        'entity_id': '${userId}_maker',
        'user_id': userId,
        'entity_name': 'Maker Shop / Products',
        'is_primary': 0,
      });
    }
  }

  /// Fetch all entities for the Waterfall Slider
  Future<List<Map<String, dynamic>>> getEntities(String userId) async {
    final db = await dbHelper.database;
    return await db.query(
        'entities',
        where: 'user_id = ?',
        whereArgs: [userId]
    );
  }
}