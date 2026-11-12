import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('burhan_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // جدول الملفات
    await db.execute('''
      CREATE TABLE files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hash TEXT NOT NULL UNIQUE,
        total_pages INTEGER DEFAULT 0,
        status TEXT DEFAULT 'ready',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول المقاطع النصية
    await db.execute('''
      CREATE TABLE chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id INTEGER NOT NULL,
        chunk_index INTEGER NOT NULL,
        text TEXT NOT NULL,
        FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
      )
    ''');
  }

  // إضافة ملف جديد
  Future<int> addFile(String name, String hash, int totalPages) async {
    final db = await instance.database;
    
    // التحقق من وجود الملف مسبقاً (لتجنب التكرار)
    final existing = await db.query('files', where: 'hash = ?', whereArgs: [hash]);
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('files', {
      'name': name,
      'hash': hash,
      'total_pages': totalPages,
    });
  }

  // إضافة مقطع نصي
  Future<int> addChunk(int fileId, int chunkIndex, String text) async {
    final db = await instance.database;
    return await db.insert('chunks', {
      'file_id': fileId,
      'chunk_index': chunkIndex,
      'text': text,
    });
  }

  // جلب جميع الملفات المحفوظة
  Future<List<Map<String, dynamic>>> getAllFiles() async {
    final db = await instance.database;
    return await db.query('files', orderBy: 'created_at DESC');
  }
}