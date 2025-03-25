import 'dart:async';

import 'package:boilerplate/domain/repository/user/user_repository.dart';
import 'package:boilerplate/data/sharedpref/shared_preference_helper.dart';
import 'package:boilerplate/domain/entity/user/user.dart';
import 'package:boilerplate/domain/usecase/user/login_usecase.dart';
import 'package:boilerplate/domain/usecase/user/register_usecase.dart';
import 'package:boilerplate/data/local/datasources/user/user_datasource.dart';

class UserRepositoryImpl extends UserRepository {
  final SharedPreferenceHelper _sharedPrefsHelper;
  final UserDataSource _userDataSource;

  UserRepositoryImpl(this._sharedPrefsHelper, this._userDataSource);

  @override
  Future<User?> login(LoginParams params) async {
    try {
      // Call the local data source for login
      final user =
          await _userDataSource.login(params.email, params.password);

      // Save login status and user data
      if (user != null) {
        await saveIsLoggedIn(true);
        await saveAuthToken(user.token);
        await saveUserId(user.id);
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User?> register(RegisterParams params) async {
    try {
      // Call the local data source for registration
      return await _userDataSource.register(params.email, params.password);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveIsLoggedIn(bool value) async {
    await _sharedPrefsHelper.saveIsLoggedIn(value);
  }

  @override
  Future<bool> get isLoggedIn => _sharedPrefsHelper.isLoggedIn;

  @override
  Future<void> saveAuthToken(String token) async {
    await _sharedPrefsHelper.saveAuthToken(token);
  }

  @override
  Future<String?> get authToken => _sharedPrefsHelper.authToken;

  @override
  Future<bool> verifyToken(String token) async {
    return _userDataSource.verifyToken(token);
  }

  @override
  Future<void> saveUserId(int id) async {
    await _sharedPrefsHelper.saveUserId(id);
  }

  @override
  Future<int?> get userId => _sharedPrefsHelper.userId;

  @override
  Future<void> logout() async {
    await _sharedPrefsHelper.logout();
  }
}
