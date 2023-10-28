import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteDatabaseHelper {

  SqfliteDatabaseHelper.internal();
  static final SqfliteDatabaseHelper instance = new SqfliteDatabaseHelper.internal();
  factory SqfliteDatabaseHelper() => instance;

  static const markTable = 'markTable';
  static const _version = 1;

  static Database? _db;

  Future<Database?> get db async {
    if (_db !=null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  Future<Database> initDb()async{
    Directory directory = await getApplicationDocumentsDirectory();
    String dbPath = join(directory.path,'syncdatabase.db');
    print(dbPath);
    var openDb = await openDatabase(dbPath,version: _version,
    onCreate: (Database db,int version)async{
      await db.execute("""
        CREATE TABLE $markTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          latitude INTEGER, 
          longitude INTEGER, 
          )""");
    },
    onUpgrade: (Database db, int oldversion,int newversion)async{
      if (oldversion<newversion) {
        print("Version Upgrade");
      }
    }
    );
    print('db initialize');
    return openDb;
  }

}