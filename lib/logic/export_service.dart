import 'dart:io';
import 'dart:ui'; // Required for Rect
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ExportService {
  /// Generates a CSV file of all finalized transactions and opens the system Share Sheet.
  /// [origin] is the screen area from which the share sheet should pop up (required for iPad/iOS).
  static Future<void> generateAndShareCsv(Rect origin) async {
    final db = await DatabaseHelper.instance.database;

    // 1. QUERY THE DATA
    // We join SPLITS (The truth) with TRANSACTIONS (The context), ENTITIES (The name), and ACCOUNTS (The source)
    // UPDATED: Added s.memo and t.notes to the query
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        t.date,
        a.institution_name,
        t.merchant_name,
        e.entity_name,
        s.category,
        s.amount_cents,
        s.memo,
        t.notes
      FROM splits s
      JOIN transactions t ON s.transaction_id = t.transaction_id
      JOIN entities e ON s.entity_id = e.entity_id
      LEFT JOIN accounts a ON t.account_id = a.account_id
      ORDER BY t.date DESC
    ''');

    if (rows.isEmpty) {
      throw Exception("No data to export.");
    }

    // 2. BUILD THE CSV CONTENT
    final buffer = StringBuffer();

    // HEADERS
    buffer.writeln('Date,Account,Merchant,Entity (Stream),Category,Split Amount,Notes / Memo');

    // ROWS
    for (var row in rows) {
      final date = row['date'].toString().substring(0, 10);
      final account = _escapeCsv(row['institution_name'] ?? 'Unknown Account');
      final merchant = _escapeCsv(row['merchant_name']);
      final entity = _escapeCsv(row['entity_name']);
      final category = row['category'];
      final amount = (row['amount_cents'] as int) / 100.0;

      // LOGIC: Use Split Memo first. If empty, use Transaction Note. If both empty, generic fallback.
      String rawNote = row['memo'] ?? row['notes'] ?? '';
      if (rawNote.isEmpty) rawNote = "User Verified via BEAMS";

      final note = _escapeCsv(rawNote);

      buffer.writeln('$date,$account,$merchant,$entity,$category,${amount.toStringAsFixed(2)},$note');
    }

    // 3. SAVE TO DISK
    final directory = await getApplicationDocumentsDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final path = '${directory.path}/BEAMS_Export_$dateStr.csv';
    final file = File(path);

    await file.writeAsString(buffer.toString());

    // 4. SHARE (AirDrop, Email, Files)
    await Share.shareXFiles(
        [XFile(path)],
        sharePositionOrigin: origin
    );
  }

  static String _escapeCsv(String? value) {
    if (value == null) return '';
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      // Standard CSV escaping: wrap in quotes, escape existing quotes
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}