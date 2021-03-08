import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/utils/utils.dart';

const _dbName = "friends_db.db";

// versions could be used to change the database schema once the app is
// already released (since you cannot ask users to reinstall the app)
const _dbVersion = 1;

const _tableName = "Friends";
const _columns = [
  "id",
  "name",
  "identifier",
  "publicKey", // the public key owned by the friend
  "latestData", // the most recent data sent by the user
  "read",
  // columns related to p2p nudging:
  "currentStepsGoal",
  "sentActiveGoal",
  "initialStepCount"
];

/// [FriendDB] is a [ChangeNotifier] that notifies listeners when any data has
/// been modified or added.
///
/// The implementation for most of the methods involves awaiting for an instance
/// of the private database connections, performing some query and then
/// returning the results.
class FriendDB extends ChangeNotifier {
  /// singleton instance of [FriendDB]
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
    initialStepCount: int,
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

  /// get the number of friends who we have received (but not read) wellbeing
  /// data from.
  Future<int> getUnreadCount() async {
    final db = await database;
    final queryString = 'SELECT COUNT(*) FROM $_tableName '
        'WHERE ${_columns[5]} = 0'; // unread when explicitly 0
    return firstIntValue(await db.rawQuery(queryString));
  }

  /// updates the latest data for all the identifiers in messages.
  /// each message should have an 'identifier_from' and 'data' index
  /// that points to their respective string values.
  Future<void> updateWellbeingData(List<dynamic> messages) async {
    final db = await database;
    final batch = db.batch(); // perform multiple queries at a time
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

  /// true if there is some friend with matching identifier
  Future<bool> isIdentifierPresent(String identifier) async {
    final db = await database;
    final query = 'SELECT COUNT(*) FROM $_tableName WHERE ${_columns[2]} = ?';
    final count = firstIntValue(await db.rawQuery(query, [identifier]));

    return count > 0;
  }

  /// mark the data associated with friend (identifier) as read
  Future<void> setRead(String identifier) async {
    final db = await database;
    db.update(_tableName, {_columns[5]: 1},
        where: '${_columns[2]} = ?', whereArgs: [identifier]);
    notifyListeners();
  }

  /// updates the flag that indicates if a nudge/goal has been sent and is active
  /// for the friend denoted by identifier
  Future<Null> updateActiveNudge(String identifier, bool isActive) async {
    final db = await database;

    final val = isActive ? 1 : 0;
    db.update(_tableName, {_columns[7]: val},
        where: '${_columns[2]} = ?', whereArgs: [identifier]);
    notifyListeners();
  }

  /// Updates the step goal from friend (denoted by identifier).
  /// stepGoal could be null.
  Future<Null> updateGoalFromFriend(
      String identifier, int stepGoal, int currentTotalStepCount) async {
    final db = await database;

    db.update(
        _tableName, {_columns[6]: stepGoal, _columns[8]: currentTotalStepCount},
        where: '${_columns[2]} = ?', whereArgs: [identifier]);
    notifyListeners();
  }

  Future<String> getName(String identifier) async {
    final db = await database;

    List<Map> maps = await db.query(_tableName,
        columns: [_columns[1]],
        where: '${_columns[2]} = ?',
        whereArgs: [identifier]);

    assert(maps.length == 1);
    return maps[0][_columns[1]];
  }

  /// get the starting step count valued stored from when the goal was first
  /// sent by identifier
  Future<int> getInitialStepCount(String identifier) async {
    final db = await database;

    List<Map> maps = await db.query(_tableName,
        columns: [_columns[8]],
        where: '${_columns[2]} = ?',
        whereArgs: [identifier]);

    assert(maps.length == 1);
    return maps[0][_columns[8]];
  }

  /// set the starting step count valued stored for a goal
  Future<Null> updateInitialStepCount(String identifier, int newVal) async {
    final db = await database;

    db.update(
      _tableName,
      {_columns[8]: newVal},
      where: '${_columns[2]} = ?',
      whereArgs: [identifier],
    );
    notifyListeners();
  }

  /// deletes a [Friend] from the database, the friend.id property must not be
  /// null
  Future<Null> deleteFriend(Friend friend) async {
    assert(friend.id != null);

    final db = await database;

    db.delete(_tableName, where: '${_columns[0]} = ?', whereArgs: [friend.id]);
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
      ${_columns[7]} INTEGER NOT NULL,
      ${_columns[8]} INTEGER
    )
      ''');
  }
}

/// Data class of a friend.
/// Allows conversion from and to a map to work better with the SQL database.
class Friend implements Comparable {
  int id;
  String name;
  String identifier;
  String publicKey;

  /// json encoded string
  String latestData;

  /// 0 if unread, otherwise 1
  int read;

  /// nullable
  int currentStepsGoal;

  /// 1 if sent & active, 0 otherwise
  int sentActiveGoal;

  /// the step count value when a step goal was first started
  int initialStepCount;

  Friend({
    this.id, // this should be left null so SQL will handle it
    this.name,
    this.identifier,
    this.publicKey,
    this.latestData,
    this.read,
    this.currentStepsGoal,
    this.sentActiveGoal,
    this.initialStepCount,
  });

  Friend.fromMap(Map<String, dynamic> map) {
    id = map[_columns[0]];
    name = map[_columns[1]];
    identifier = map[_columns[2]];
    publicKey = map[_columns[3]];
    latestData = map[_columns[4]];
    read = map[_columns[5]];
    currentStepsGoal = map[_columns[6]];
    sentActiveGoal = map[_columns[7]];
    initialStepCount = map[_columns[8]];
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
      // initialStepCount nullable
    };
    if (id != null) {
      map[_columns[0]] = id;
    }
    if (currentStepsGoal != null) {
      map[_columns[6]] = currentStepsGoal;
    }
    if (initialStepCount != null) {
      map[_columns[8]] = initialStepCount;
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
