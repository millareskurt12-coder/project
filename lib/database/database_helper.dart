import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  DatabaseHelper._([this._databasePath]);

  DatabaseHelper.forTesting(String databasePath) : this._(databasePath);

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'pockettrack.db';
  static const _databaseVersion = 1;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if ((Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      databaseFactory = databaseFactoryFfi;
    }
    _database = await openDatabase(
      _databasePath ?? path.join(await getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createTables,
    );
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        UNIQUE (user_id, month),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX transactions_user_date ON transactions(user_id, date)',
    );
  }

  Future<UserModel?> findUserByUsername(String username) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<Map<String, Object?>?> findUserWithHash(String username) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<UserModel> createUser({
    required String fullName,
    required String username,
    required String passwordHash,
  }) async {
    final db = await database;
    final id = await db.insert('users', {
      'full_name': fullName.trim(),
      'username': username.trim(),
      'password_hash': passwordHash,
    });
    return UserModel(
      id: id,
      fullName: fullName.trim(),
      username: username.trim(),
    );
  }

  Future<UserModel?> getUserById(int userId) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<void> saveRememberedUser(int userId) async {
    final db = await database;
    await db.insert('sessions', {
      'id': 1,
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getRememberedUser() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT users.id, users.full_name, users.username
      FROM sessions JOIN users ON users.id = sessions.user_id
      WHERE sessions.id = 1
      LIMIT 1
    ''');
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<void> clearRememberedUser() async {
    final db = await database;
    await db.delete('sessions', where: 'id = 1');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions(int userId) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('An existing transaction id is required.');
    }
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap()..remove('id'),
      where: 'id = ? AND user_id = ?',
      whereArgs: [transaction.id, transaction.userId],
    );
  }

  Future<void> deleteTransaction(int transactionId, int userId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [transactionId, userId],
    );
  }

  Future<BudgetModel?> getBudget(int userId, String month) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: 'user_id = ? AND month = ?',
      whereArgs: [userId, month],
      limit: 1,
    );
    return rows.isEmpty ? null : BudgetModel.fromMap(rows.first);
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
