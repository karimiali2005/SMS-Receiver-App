// ✅ Updated `database_service.dart`
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sms_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'sms_receiver.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT,
            body TEXT,
            timestamp TEXT,
            isManual INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertMessage(SmsMessageModel msg) async {
    final prefs = await SharedPreferences.getInstance();
    final allowedList = prefs.getStringList("allowedSenders") ?? [];

    String normalize(String number) => number.replaceAll(RegExp(r'[\s+]'), '');

    final normalizedSender = normalize(msg.sender);
    final isAllowed = allowedList
        .map(normalize)
        .any((allowed) => normalizedSender.contains(allowed));

    if (!isAllowed) {
      print("❌ Skipping SMS from ${msg.sender} - Not allowed");
      return;
    }

    final existsAlready = await exists(msg);
    if (existsAlready) {
      print("⚠️ Duplicate SMS skipped from ${msg.sender}");
      return;
    }

    final db = await database;
    await db.insert(
      'messages',
      msg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("✅ Inserted SMS from ${msg.sender}");
  }

  Future<List<SmsMessageModel>> getMessages() async {
    final db = await database;
    final maps = await db.query('messages');
    return maps.map((m) => SmsMessageModel.fromMap(m)).toList();
  }

  Future<bool> exists(SmsMessageModel sms) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'sender = ? AND body = ? AND timestamp = ?',
      whereArgs: [sms.sender, sms.body, sms.timestamp],
    );
    return result.isNotEmpty;
  }

  Future<void> deleteMessage(SmsMessageModel sms) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'sender = ? AND body = ? AND timestamp = ?',
      whereArgs: [sms.sender, sms.body, sms.timestamp],
    );
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('messages');
  }
}
