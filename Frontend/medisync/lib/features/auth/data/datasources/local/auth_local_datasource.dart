import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/network/token_local_datasource.dart';
import '../../models/user_dto.dart';

abstract interface class AuthLocalDataSource implements TokenLocalDataSource {
  Future<void> saveToken(String jwt);
  Future<void> saveUser(UserDto user);
  Future<UserDto?> readUser();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _keyToken = 'jwt_token';
  static const _keyUser = 'current_user';

  final FlutterSecureStorage _storage;

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> saveToken(String jwt) async {
    await _storage.write(key: _keyToken, value: jwt);
  }

  @override
  Future<String?> readToken() async {
    return _storage.read(key: _keyToken);
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: _keyToken);
  }

  @override
  Future<void> saveUser(UserDto user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  @override
  Future<UserDto?> readUser() async {
    try {
      final raw = await _storage.read(key: _keyUser);
      if (raw == null) return null;
      return UserDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const CacheException('No se pudo leer el usuario almacenado.');
    }
  }

  @override
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
