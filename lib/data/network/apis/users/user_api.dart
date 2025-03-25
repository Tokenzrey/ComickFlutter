import 'dart:async';

import 'package:boilerplate/core/data/network/dio/dio_client.dart';
import 'package:boilerplate/data/network/constants/endpoints.dart';
import 'package:boilerplate/data/network/rest_client.dart';
import 'package:boilerplate/domain/entity/user/user.dart';
import 'package:flutter/foundation.dart';

class UserApi {
  // Instance Dio untuk melakukan request
  final DioClient _dioClient;

  // ignore: unused_field
  final RestClient _restClient;

  // Injeksi dependency melalui constructor
  UserApi(this._dioClient, this._restClient);

  /// Melakukan login user dengan mengirimkan [email] dan [password].
  /// Mengembalikan instance [User] jika berhasil.
  Future<User> login(String email, String password) async {
    try {
      final res = await _dioClient.dio.post(
        Endpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return User.fromMap(res.data);
    } catch (e) {
      if (kDebugMode) {
        print("UserApi.login error: ${e.toString()}");
      }
      rethrow;
    }
  }

  /// Melakukan registrasi user dengan mengirimkan [email] dan [password].
  /// Mengembalikan instance [User] jika registrasi berhasil.
  Future<User> register(String email, String password) async {
    try {
      final res = await _dioClient.dio.post(
        Endpoints.register,
        data: {
          'email': email,
          'password': password,
        },
      );
      return User.fromMap(res.data);
    } catch (e) {
      if (kDebugMode) {
        print("UserApi.register error: ${e.toString()}");
      }
      rethrow;
    }
  }

  /// Mengambil data user berdasarkan [id].
  /// Mengembalikan instance [User] jika ditemukan.
  Future<User> getUserById(int id) async {
    try {
      final res = await _dioClient.dio.get(
        '${Endpoints.getUser}/$id',
      );
      return User.fromMap(res.data);
    } catch (e) {
      if (kDebugMode) {
        print("UserApi.getUserById error: ${e.toString()}");
      }
      rethrow;
    }
  }
}
