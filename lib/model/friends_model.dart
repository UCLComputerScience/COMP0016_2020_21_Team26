import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/utils/utils.dart';

const _dbName = "friends_db.db";
const _dbVersion = 1;

const _tableName = "Friends";
const _columns = [
  "id",
  "name",
  "identifier",
  "publicKey",
  "latestData",
  "read",
  "currentStepsGoal",
  "sentActiveGoal",
];

class FriendDB extends ChangeNotifier {
  static final FriendDB _instance = FriendDB._();
  static Database _database;

  FriendDB._(); // private constructor
  factory FriendDB() => _instance; // factory so we don't return new instance

  /// inserts a wellbeing record.
  /// returns the id of the newly inserted record
  Future<int> insert(Friend item) async {
    final db = await database;
    final id = await db.insert(_tableName, item.toMap());
    notifyListeners();
    return id;
  }

  /// inserts a [WellbeingItem] constructed with the given data.
  /// returns the id of the newly inserted record
  Future<int> insertWithData({
    name: String,
    identifier: String,
    publicKey: String,
    latestData: String,
    read: int,
    currentStepsGoal: int,
    sentActiveGoal: int,
  }) async {
    assert(sentActiveGoal != null);
    return insert(Friend(
      name: name,
      identifier: identifier,
      publicKey: publicKey,
      latestData: latestData,
      read: read,
      currentStepsGoal: currentStepsGoal,
      sentActiveGoal: sentActiveGoal,
    ));
  }

  Future<List<Friend>> getFriends() async {
    final db = await database;
    List<Map> friendMaps = await db.query(_tableName, columns: _columns);
    final itemList = friendMaps
        .map((friendMap) => Friend.fromMap(friendMap))
        .toList(growable: false);
    return itemList;
  }

  /// updates the latest data for all the identifiers in messages.
  /// each message should have an 'identifier_from' and 'data' index
  /// that points to their respective string values.
  Future<void> updateData(List<dynamic> messages) async {
    final db = await database;
    final batch = db.batch();
    for (var message in messages) {
      final sender = message['identifier_from'];
      final data = message['data'];
      // update the row with the new data and mark it unread
      batch.update(_tableName, {_columns[4]: data, _columns[5]: 0},
          where: '${_columns[2]} = ?', whereArgs: [sender]);
    }
    await batch.commit();
    notifyListeners();
  }

  /// get the latest data sent by identifier.
  /// NOTE: may be null
  Future<String> getLatestData(String identifier) async {
    final db = await database;
    List<Map> friendMaps = await db.query(_tableName,
        columns: [_columns[4]],
        where: '${_columns[2]} = ?',
        whereArgs: [identifier]);
    assert(friendMaps.length == 1);
    final out = friendMaps[0][_columns[4]];

    return out == null ? "" : out;
  }

  Future<bool> isIdentifierPresent(String identifier) async {
    final db = await database;
    final query = 'SELECT COUNT(*) FROM $_tableName WHERE ${_columns[2]} = ?';
    final count = firstIntValue(await db.rawQuery(query, [identifier]));

    return count > 0;
  }

  Future<void> setRead(String identifier) async {
    final db = await database;
    db.update(_tableName, {_columns[5]: 1},
        where: '${_columns[2]} = ?', whereArgs: [identifier]);
    notifyListeners();
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
      ${_columns[1]} TEXT NOT NULL,
      ${_columns[2]} TEXT NOT NULL,
      ${_columns[3]} TEXT NOT NULL,
      ${_columns[4]} TEXT,
      ${_columns[5]} INTEGER,
      ${_columns[6]} INTEGER,
      ${_columns[7]} INTEGER NOT NULL
    )
      ''');
  }
}

/// Data class of a friend
class Friend implements Comparable {
  int id;
  String name;
  String identifier;
  String publicKey;

  /// json encoded string
  String latestData;

  /// 0 if unread, otherwise 1
  int read;

  // nullable
  int currentStepsGoal;

  // 1 if sent & active, 0 otherwise
  int sentActiveGoal;

  Friend(
      {this.id, // this should be left null so SQL will handle it
      this.name,
      this.identifier,
      this.publicKey,
      this.latestData,
      this.read,
      this.currentStepsGoal,
      this.sentActiveGoal});

  Friend.fromMap(Map<String, dynamic> map) {
    id = map[_columns[0]];
    name = map[_columns[1]];
    identifier = map[_columns[2]];
    publicKey = map[_columns[3]];
    latestData = map[_columns[4]];
    read = map[_columns[5]];
    currentStepsGoal = map[_columns[6]];
    sentActiveGoal = map[_columns[7]];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      // id might be null
      _columns[1]: name,
      _columns[2]: identifier,
      _columns[3]: publicKey,
      _columns[4]: latestData,
      _columns[5]: read,
      // currentStepsGoal nullable
      _columns[7]: sentActiveGoal,
    };
    if (id != null) {
      map[_columns[0]] = id;
    }
    if (currentStepsGoal != null) {
      map[_columns[6]] = currentStepsGoal;
    }
    return map;
  }

  /// unread Friends < read Friends
  @override
  int compareTo(other) {
    final check1 = this.read == null ? 1 : this.read;
    final check2 = other.read == null ? 1 : other.read;
    return check1.compareTo(check2);
  }
}
