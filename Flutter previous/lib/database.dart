import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;

class DatabaseHelper {
  static final DatabaseHelper _databaseHelper = DatabaseHelper._();
  DatabaseHelper._();
  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  factory DatabaseHelper() {
    return _databaseHelper;
  }

  initDb() async {
    print("Created db");

    String dbDir = await getDatabasesPath();
    String path = join(dbDir, "location_Data.db");
    var theDb = await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) {
      db.execute(
          'CREATE TABLE locationdata(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, timeSpan DATETIME , lat DOUBLE,long  DOUBLE )');
    });
    print(path);
    print("i am create db: $theDb");
    return theDb;
  }

  insertData(LocationData locationData) async {
    // Get a reference to the database.
    final databaseClient = await db;

    await databaseClient!.insert(
      'locationdata',
      locationData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LocationData>> getAll() async {
    // Get a reference to the database.
    final databaseClient = await db;

    final List<Map<String, dynamic>> maps =
        await databaseClient!.query('locationdata');

    return List.generate(maps.length, (i) {
      return LocationData(
        timeSpan: maps[i]['timeSpan'],
        lat: maps[i]['lat'],
        long: maps[i]['long'],
      );
    });
  }
}

class LocationData {
  int timeSpan;
  final double lat;
  final double long;
  // final int accuracy;
  LocationData({required this.timeSpan, required this.lat, required this.long});

  Map<String, dynamic> toMap() {
    return {
      'timeSpan': timeSpan,
      'lat': lat,
      'long': long,
    };
  }

  @override
  String toString() {
    return 'LocationData{ timeSpan: $timeSpan, lat: $lat, long:$long}';
  }
}
