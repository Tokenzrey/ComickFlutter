// ignore: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';

import '../../../core/domain/usecase/use_case.dart';
import '../../entity/user/user.dart';
import '../../repository/user/user_repository.dart';

part 'register_usecase.g.dart';

/// Class ini digunakan untuk mengemas parameter registrasi
/// yang diperlukan dalam proses registrasi.
@JsonSerializable()
class RegisterParams {
  final String email;
  final String password;

  RegisterParams({
    required this.email,
    required this.password,
  });

  factory RegisterParams.fromJson(Map<String, dynamic> json) =>
      _$RegisterParamsFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterParamsToJson(this);
}

/// Use case untuk proses registrasi pengguna.
/// Use case ini memanggil method [register] dari [UserRepository]
/// dengan parameter [RegisterParams] dan mengembalikan entity [User] jika berhasil.
class RegisterUseCase implements UseCase<User?, RegisterParams> {
  final UserRepository _userRepository;

  RegisterUseCase(this._userRepository);

  @override
  Future<User?> call({required RegisterParams params}) async {
    return _userRepository.register(params);
  }
}
