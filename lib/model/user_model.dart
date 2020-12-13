import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/utils/utils.dart';

const dbName = "wellbeing_items_db.db";
const dbVersion = 1;

const tableName = "WellbeingItems";
const columns = [
  "id",
  "date",
  "postcode",
  "wellbeing_score",
  "steps",
  "support_code"
];

/// Singleton class to read/write to DB
class UserWellbeingDB {
  static final UserWellbeingDB _instance = UserWellbeingDB._();
  static Database _database;

  UserWellbeingDB._(); // private constructor
  factory UserWellbeingDB() =>
      _instance; // factory so we don't return new instance

  /// inserts a wellbeing record.
  /// returns the id of the newly inserted record
  Future<int> insert(WellbeingItem item) async {
    final db = await database;
    final id = await db.insert(tableName, item.toMap());
    return id;
  }

  /// returns up to n wellbeing items
  Future<List<WellbeingItem>> getLastNWeeks(int n) async {
    final db = await database;
    List<Map> wellbeingMaps = await db.query(tableName,
        columns: columns, orderBy: "${columns[0]} DESC", limit: n);
    return wellbeingMaps
        .map((wellbeingMap) => WellbeingItem.fromMap(wellbeingMap))
        .toList(growable: false);
  }

  void delete() async {
    final base = await getDatabasesPath();
    deleteDatabase(join(base, dbName));
    _database = null; // will be created next time its needed
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await _init();
    }
    return _database;
  }

  Future<bool> get empty async {
    final db = await database;
    return firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName')) >
        0;
  }

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final dbPath = join(dir, dbName);
    return openDatabase(dbPath, version: dbVersion, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) {
    db.execute('''
      CREATE TABLE $tableName (
      ${columns[0]} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${columns[1]} TEXT,
      ${columns[2]} TEXT,
      ${columns[3]} DOUBLE,
      ${columns[4]} INTEGER,
      ${columns[5]} TEXT
    )
      ''');
  }
}

/// Immutable data item of a week's wellbeing record
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
    id = map[columns[0]];
    date = map[columns[1]];
    postcode = map[columns[2]];
    wellbeingScore = map[columns[3]];
    numSteps = map[columns[4]];
    supportCode = map[columns[5]];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      // id might be null
      columns[1]: date,
      columns[2]: postcode,
      columns[3]: wellbeingScore,
      columns[4]: numSteps,
      columns[5]: supportCode,
    };
    if (id != null) {
      map[columns[0]] = id;
    }
    return map;
  }
}
