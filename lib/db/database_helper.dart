import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('entries.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> insertOrUpdateEntry(Entry entry) async {
    final db = await instance.database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE entries (
        id $idType,
        userId $textType,
        title $textType,
        description $textType,
        category $textType,
        date $textType,
        mood $textType,          -- ✅ added mood column
        imagePath $textType,
        isSynced $boolType
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE entries ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE entries ADD COLUMN userId TEXT");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE entries ADD COLUMN mood TEXT");
      await db.execute("UPDATE entries SET mood = '😊' WHERE mood IS NULL");
    }
  }

  Future<int> insertEntry(Entry entry) async {
    final db = await instance.database;
    return await db.insert('entries', entry.toMap());
  }

  Future<List<Entry>> getEntries(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'entries',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((map) => Entry.fromMap(map)).toList();
  }

  Future<List<Entry>> getUnsyncedEntries(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'entries',
      where: 'isSynced = ? AND userId = ?',
      whereArgs: [0, userId],
    );
    return result.map((map) => Entry.fromMap(map)).toList();
  }

  Future<int> updateEntry(Entry entry) async {
    final db = await instance.database;
    return await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
