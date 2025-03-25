import 'package:boilerplate/core/data/local/sembast/sembast_client.dart';
import 'package:boilerplate/data/local/constants/db_constants.dart';
import 'package:boilerplate/domain/entity/user/user.dart';
import 'package:boilerplate/utils/security/security_utils.dart';
import 'package:sembast/sembast.dart';
import 'package:flutter/foundation.dart';

class UserDataSource {
  final _usersStore = intMapStoreFactory.store(DBConstants.USER_STORE_NAME);
  final SembastClient _sembastClient;

  UserDataSource(this._sembastClient);

  // Check if email already exists
  Future<bool> isEmailExists(String email) async {
    final finder = Finder(filter: Filter.equals('email', email));
    final records =
        await _usersStore.find(_sembastClient.database, finder: finder);
    return records.isNotEmpty;
  }

  // Register a new user
  Future<User?> register(String email, String password) async {
    try {
      // Check if email already exists
      final emailExists = await isEmailExists(email);
      if (emailExists) {
        throw Exception('Email already exists');
      }

      // Hash the password
      final hashedPassword = SecurityUtils.hashPassword(password);

      // Generate a unique ID
      final id = SecurityUtils.generateUniqueId();

      // Generate a token
      final token = SecurityUtils.generateJwtToken(id, email);

      // Create the user
      final user = User(
        id: id,
        email: email,
        password: hashedPassword,
        token: token,
      );

      // Insert into database
      await _usersStore.record(id).put(_sembastClient.database, user.toMap());

      // Return the user with masked password
      return User(
        id: id,
        email: email,
        password: '*****',
        token: token,
      );
    } catch (e) {
      if (kDebugMode) {
        print("UserDataSource.register error: ${e.toString()}");
      }
      rethrow;
    }
  }

  // Login a user
  Future<User?> login(String email, String password) async {
    try {
      // Find the user by email
      final finder = Finder(filter: Filter.equals('email', email));
      final record =
          await _usersStore.findFirst(_sembastClient.database, finder: finder);

      if (record == null) {
        throw Exception('User not found');
      }

      // Get the stored hashed password
      final storedUser = User.fromMap(record.value);
      final storedHashedPassword = storedUser.password;

      // Hash the input password and compare
      final inputHashedPassword = SecurityUtils.hashPassword(password);

      if (inputHashedPassword != storedHashedPassword) {
        throw Exception('Invalid password');
      }

      // Generate a new token
      final token = SecurityUtils.generateJwtToken(storedUser.id, email);

      // Update the token in the database
      final updatedUser = User(
        id: storedUser.id,
        email: storedUser.email,
        password: storedUser.password,
        token: token,
      );

      await update(updatedUser);

      // Return the user with masked password
      return User(
        id: storedUser.id,
        email: storedUser.email,
        password: '*****',
        token: token,
      );
    } catch (e) {
      if (kDebugMode) {
        print("UserDataSource.login error: ${e.toString()}");
      }
      rethrow;
    }
  }

  // Verify token
  Future<bool> verifyToken(String token) async {
    return SecurityUtils.verifyToken(token);
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    final recordSnapshots = await _usersStore.find(_sembastClient.database);
    return recordSnapshots.map((snapshot) {
      final user = User.fromMap(snapshot.value);
      return User(
        id: snapshot.key,
        email: user.email,
        password: "*****",
        token: user.token,
      );
    }).toList();
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    final record = await _usersStore.record(id).get(_sembastClient.database);
    if (record != null) {
      final user = User.fromMap(record);
      return User(
        id: id,
        email: user.email,
        password: "*****",
        token: user.token,
      );
    }
    return null;
  }

  // Update user
  Future<int> update(User user) async {
    final finder = Finder(filter: Filter.byKey(user.id));
    return await _usersStore.update(
      _sembastClient.database,
      user.toMap(),
      finder: finder,
    );
  }

  // Update password
  Future<int> updatePassword(int id, String newPassword) async {
    final record = await _usersStore.record(id).get(_sembastClient.database);
    if (record != null) {
      final updatedMap = Map<String, dynamic>.from(record);
      updatedMap['password'] = SecurityUtils.hashPassword(newPassword);

      final finder = Finder(filter: Filter.byKey(id));
      return await _usersStore.update(
        _sembastClient.database,
        updatedMap,
        finder: finder,
      );
    }
    throw Exception("User with id $id not found");
  }

  // Delete user
  Future<int> delete(User user) async {
    final finder = Finder(filter: Filter.byKey(user.id));
    return await _usersStore.delete(
      _sembastClient.database,
      finder: finder,
    );
  }

  // Delete all users
  Future deleteAll() async {
    await _usersStore.drop(_sembastClient.database);
  }
}
