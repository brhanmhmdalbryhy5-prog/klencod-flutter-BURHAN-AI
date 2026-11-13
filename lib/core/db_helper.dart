import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('burhan_ai_final.db');
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
    await db.execute('''
      CREATE TABLE files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hash TEXT NOT NULL UNIQUE,
        total_pages INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id INTEGER NOT NULL,
        chunk_index INTEGER NOT NULL,
        text TEXT NOT NULL,
        FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE learned_qa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> addFile(String name, String hash, int totalPages) async {
    final db = await instance.database;
    final existing = await db.query('files', where: 'hash = ?', whereArgs: [hash]);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await db.insert('files', {'name': name, 'hash': hash, 'total_pages': totalPages});
  }

  Future<int> addChunk(int fileId, int chunkIndex, String text) async {
    final db = await instance.database;
    return await db.insert('chunks', {'file_id': fileId, 'chunk_index': chunkIndex, 'text': text});
  }

  Future<List<Map<String, dynamic>>> getAllFiles() async {
    final db = await instance.database;
    return await db.query('files', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllChunks() async {
    final db = await instance.database;
    return await db.query('chunks');
  }

  Future<Map<String, dynamic>?> getRandomChunk(int fileId) async {
    final db = await instance.database;
    final results = await db.query('chunks', where: 'file_id = ?', whereArgs: [fileId], orderBy: 'RANDOM()', limit: 1);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<void> addLearnedQA(String question, String answer) async {
    final db = await instance.database;
    await db.insert('learned_qa', {'question': question, 'answer': answer});
  }

  Future<List<Map<String, dynamic>>> getAllLearnedQA() async {
    final db = await instance.database;
    return await db.query('learned_qa');
  }

  Future<int> createSession(String title) async {
    final db = await instance.database;
    return await db.insert('sessions', {'title': title});
  }

  Future<void> addMessage(int sessionId, String role, String content) async {
    final db = await instance.database;
    await db.insert('messages', {'session_id': sessionId, 'role': role, 'content': content});
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await instance.database;
    return await db.query('sessions', orderBy: 'created_at DESC');
  }
}