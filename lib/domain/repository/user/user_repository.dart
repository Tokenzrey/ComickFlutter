import 'dart:async';

import 'package:boilerplate/domain/usecase/user/login_usecase.dart';
import 'package:boilerplate/domain/usecase/user/register_usecase.dart';

import '../../entity/user/user.dart';

abstract class UserRepository {
  Future<User?> login(LoginParams params);

  Future<User?> register(RegisterParams params);

  Future<void> saveIsLoggedIn(bool value);

  Future<bool> get isLoggedIn;

  Future<void> saveAuthToken(String token);

  Future<String?> get authToken;

  Future<bool> verifyToken(String token);

  Future<void> saveUserId(int id);

  Future<int?> get userId;

  Future<void> logout();
}
