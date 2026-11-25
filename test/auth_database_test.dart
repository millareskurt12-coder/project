import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:pocket_track/database/database_helper.dart';
import 'package:pocket_track/models/budget_model.dart';
import 'package:pocket_track/models/transaction_model.dart';
import 'package:pocket_track/services/auth_service.dart';
import 'package:pocket_track/services/session_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDirectory;
  late DatabaseHelper database;
  late AuthService auth;
  late SessionService sessions;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('pockettrack_test_');
    database = DatabaseHelper.forTesting(
      path.join(tempDirectory.path, 'test.db'),
    );
    auth = AuthService(database: database);
    sessions = SessionService(database: database);
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'registration, login, remembered session, and financial data stay scoped',
    () async {
      final firstUser = await auth.register(
        fullName: 'Alex Example',
        username: 'alex',
        password: 'secure-password-1',
      );
      final secondUser = await auth.register(
        fullName: 'Sam Example',
        username: 'sam',
        password: 'secure-password-2',
      );

      final storedUser = await database.findUserWithHash('alex');
      final storedHash = storedUser!['password_hash'] as String;
      expect(storedHash, isNot('secure-password-1'));
      expect(storedHash, startsWith('pbkdf2_sha256\$120000\$'));
      expect(
        (await auth.login(username: 'alex', password: 'secure-password-1'))?.id,
        firstUser.id,
      );
      expect(
        await auth.login(username: 'alex', password: 'wrong-password'),
        isNull,
      );
      expect(
        await auth.login(username: 'missing', password: 'anything'),
        isNull,
      );
      expect(await auth.usernameExists('ALEX'), isTrue);

      await sessions.rememberUser(firstUser);
      expect((await sessions.getRememberedUser())?.id, firstUser.id);

      final firstTransactionId = await database.insertTransaction(
        TransactionModel(
          userId: firstUser.id,
          title: 'Groceries',
          amount: 25,
          type: 'Expense',
          category: 'Food',
          date: '2026-11-25',
        ),
      );
      await database.insertTransaction(
        TransactionModel(
          userId: secondUser.id,
          title: 'Bus pass',
          amount: 12,
          type: 'Expense',
          category: 'Transport',
          date: '2026-11-25',
        ),
      );
      await database.saveBudget(
        BudgetModel(userId: firstUser.id, amount: 500, month: '2026-11'),
      );
      await database.saveBudget(
        BudgetModel(userId: secondUser.id, amount: 200, month: '2026-11'),
      );

      expect(
        (await database.getTransactions(firstUser.id))
            .map((item) => item.title),
        ['Groceries'],
      );
      expect(
        (await database.getTransactions(secondUser.id))
            .map((item) => item.title),
        ['Bus pass'],
      );
      expect((await database.getBudget(firstUser.id, '2026-11'))?.amount, 500);
      expect((await database.getBudget(secondUser.id, '2026-11'))?.amount, 200);

      await database.deleteTransaction(firstTransactionId, secondUser.id);
      expect((await database.getTransactions(firstUser.id)), hasLength(1));

      await sessions.clearSession();
      expect(await sessions.getRememberedUser(), isNull);
      expect((await database.getTransactions(firstUser.id)), hasLength(1));
    },
  );
}
