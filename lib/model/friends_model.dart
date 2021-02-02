import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/pointycastle.dart';
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
  "read"
];

class FriendDB {
  static final FriendDB _instance = FriendDB._();
  static Database _database;

  FriendDB._(); // private constructor
  factory FriendDB() => _instance; // factory so we don't return new instance

  /// inserts a wellbeing record.
  /// returns the id of the newly inserted record
  Future<int> insert(Friend item) async {
    final db = await database;
    final id = await db.insert(_tableName, item.toMap());
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
  }) async {
    return insert(Friend(
      name: name,
      identifier: identifier,
      publicKey: publicKey,
      latestData: latestData,
      read: read,
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

  /// get the public key associated with the [Friend] 'identifier'
  Future<RSAPublicKey> getKey(String identifier) async {
    final db = await database;
    List<Map> friendMaps = await db.query(_tableName,
        columns: [_columns[3]],
        where: '${_columns[2]} = ?',
        whereArgs: [identifier]);
    assert(friendMaps.length == 1);
    final String keyString = friendMaps[0][_columns[3]];
    return RSAKeyParser().parse(keyString) as RSAPublicKey;
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
  }

  void delete() async {
    final base = await getDatabasesPath();
    deleteDatabase(join(base, _dbName));
    _database = null; // will be created next time its needed
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
      ${_columns[5]} INTEGER
    )
      ''');
  }
}

/// (Effectively) immutable data item of a friend
class Friend {
  int id;
  String name;
  String identifier;
  String publicKey;
  String latestData; // json encoded string
  int read;

  Friend({
    this.id, // this should be left null so SQL will handle it
    this.name,
    this.identifier,
    this.publicKey,
    this.latestData,
    this.read,
  });

  Friend.fromMap(Map<String, dynamic> map) {
    id = map[_columns[0]];
    name = map[_columns[1]];
    identifier = map[_columns[2]];
    publicKey = map[_columns[3]];
    latestData = map[_columns[4]];
    read = map[_columns[5]];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      // id might be null
      _columns[1]: name,
      _columns[2]: identifier,
      _columns[3]: publicKey,
      _columns[4]: latestData,
      _columns[5]: read,
    };
    if (id != null) {
      map[_columns[0]] = id;
    }
    return map;
  }
}
