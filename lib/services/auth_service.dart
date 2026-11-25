import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({DatabaseHelper? database})
    : _database = database ?? DatabaseHelper.instance;

  static const _iterations = 120000;
  final DatabaseHelper _database;

  Future<bool> usernameExists(String username) async {
    return await _database.findUserByUsername(username.trim()) != null;
  }

  Future<UserModel> register({
    required String fullName,
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (await usernameExists(normalizedUsername)) {
      throw const UsernameAlreadyExistsException();
    }
    return _database.createUser(
      fullName: fullName.trim(),
      username: normalizedUsername,
      passwordHash: _hashPassword(password),
    );
  }

  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    final row = await _database.findUserWithHash(username.trim());
    if (row == null) return null;
    final encodedHash = row['password_hash'] as String;
    if (!_verifyPassword(password, encodedHash)) return null;
    return UserModel.fromMap(row);
  }

  String _hashPassword(String password) {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = _pbkdf2(utf8.encode(password), salt, _iterations);
    return 'pbkdf2_sha256\$$_iterations\$${_toHex(salt)}\$${_toHex(hash)}';
  }

  bool _verifyPassword(String password, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 ||
        parts[0] != 'pbkdf2_sha256' ||
        int.tryParse(parts[1]) != _iterations) {
      return false;
    }
    final salt = _fromHex(parts[2]);
    final expected = _fromHex(parts[3]);
    if (salt == null || expected == null || expected.length != 32) return false;
    final actual = _pbkdf2(utf8.encode(password), salt, _iterations);
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ actual[i];
    }
    return difference == 0;
  }

  Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    final blockSalt = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt);
    blockSalt[salt.length + 3] = 1;
    var block = hmac.convert(blockSalt).bytes;
    final result = List<int>.from(block);
    for (var iteration = 1; iteration < iterations; iteration++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
    }
    return Uint8List.fromList(result);
  }

  String _toHex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  List<int>? _fromHex(String value) {
    if (value.length.isOdd || !RegExp(r'^[0-9a-f]+$').hasMatch(value)) {
      return null;
    }
    return [
      for (var index = 0; index < value.length; index += 2)
        int.parse(value.substring(index, index + 2), radix: 16),
    ];
  }
}

class UsernameAlreadyExistsException implements Exception {
  const UsernameAlreadyExistsException();
}
