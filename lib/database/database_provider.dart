import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  static final DatabaseProvider dbProvider = DatabaseProvider();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await createDatabase();
    return _database!;
  }

  createDatabase() async {
    var dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, 'locationDB.db'),
      version: 1,
      onCreate: (Database database, int version) async {
        await database.execute(
          "CREATE TABLE mytable("
          "latitude REAL NOT NULL,"
          "longitude REAL NOT NULL,"
          "speed INTEGER NOT NULL,"
          "created_at TEXT DEFAULT (datetime('now'))"
          ")",
        );
      },
    );
  }
}
