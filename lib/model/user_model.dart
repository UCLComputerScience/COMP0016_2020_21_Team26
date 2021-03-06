import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/utils/utils.dart';

const _dbName = "wellbeing_items_db.db";

// versions could be used to change the database schema once the app is
// already released (since you cannot ask users to reinstall the app)
const _dbVersion = 1;

const _tableName = "WellbeingItems";
const _columns = [
  "id",
  "date",
  "postcode",
  "wellbeing_score",
  "steps",
  "support_code"
];

/// Singleton [ChangeNotifier] to read/write to DB.
/// Stores the user's wellbeing scores and steps.
class UserWellbeingDB extends ChangeNotifier {
  static final UserWellbeingDB _instance = UserWellbeingDB._();
  static Database _database;

  UserWellbeingDB._(); // private constructor
  factory UserWellbeingDB() =>
      _instance; // factory so we don't return new instance

  /// inserts a wellbeing record.
  /// returns the id of the newly inserted record
  Future<int> insert(WellbeingItem item) async {
    final db = await database;
    final id = await db.insert(_tableName, item.toMap());
    notifyListeners();
    return id;
  }

  /// inserts a [WellbeingItem] constructed with the given data.
  /// returns the id of the newly inserted record
  Future<int> insertWithData(
      {date: String,
      postcode: String,
      wellbeingScore: double,
      numSteps: int,
      supportCode: String}) async {
    assert(wellbeingScore != null);
    return insert(WellbeingItem(
      id: null,
      date: date,
      postcode: postcode,
      wellbeingScore: wellbeingScore,
      numSteps: numSteps,
      supportCode: supportCode,
    ));
  }

  /// returns up to n wellbeing items
  Future<List<WellbeingItem>> getLastNWeeks(int n) async {
    final db = await database;
    List<Map> wellbeingMaps = await db.query(_tableName,
        columns: _columns, orderBy: "${_columns[0]} DESC", limit: n);
    final itemList = wellbeingMaps
        .map((wellbeingMap) => WellbeingItem.fromMap(wellbeingMap))
        .toList(growable: false);
    itemList.sort((a, b) => a.id.compareTo(b.id));
    return itemList;
  }

  void delete() async {
    final base = await getDatabasesPath();
    deleteDatabase(join(base, _dbName));
    _database = null; // will be created next time its needed
    notifyListeners();
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await _init();
    }
    return _database;
  }

  /// returns `true` if there are 0 rows in the DB
  Future<bool> get empty async {
    final db = await database;
    return firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_tableName')) ==
        0;
  }

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final dbPath = join(dir, _dbName);
    return openDatabase(dbPath, version: _dbVersion, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) {
    db.execute('''
      CREATE TABLE $_tableName (
      ${_columns[0]} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${_columns[1]} TEXT,
      ${_columns[2]} TEXT,
      ${_columns[3]} DOUBLE,
      ${_columns[4]} INTEGER,
      ${_columns[5]} TEXT
    )
      ''');
  }
}

/// Data item of a week's wellbeing record.
class WellbeingItem {
  int id;
  String date;
  String postcode; // it's possible that the user moves house
  double wellbeingScore;
  int numSteps;
  String supportCode;

  WellbeingItem(
      {this.id, // this should prob be left null so SQL will handle it
      this.date,
      this.postcode,
      this.wellbeingScore,
      this.numSteps,
      this.supportCode});

  WellbeingItem.fromMap(Map<String, dynamic> map) {
    id = map[_columns[0]];
    date = map[_columns[1]];
    postcode = map[_columns[2]];
    wellbeingScore = map[_columns[3]];
    numSteps = map[_columns[4]];
    supportCode = map[_columns[5]];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      // id might be null
      _columns[1]: date,
      _columns[2]: postcode,
      _columns[3]: wellbeingScore,
      _columns[4]: numSteps,
      _columns[5]: supportCode,
    };
    if (id != null) {
      map[_columns[0]] = id;
    }
    return map;
  }
}
