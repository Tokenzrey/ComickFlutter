import 'package:boilerplate/domain/repository/user/user_repository.dart';

class AuthService {
  final UserRepository _userRepository;

  AuthService(this._userRepository);

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _userRepository.isLoggedIn;
  }

  // Verify token
  Future<bool> verifyAuthentication() async {
    final token = await _userRepository.authToken;
    if (token == null) return false;
    return await _userRepository.verifyToken(token);
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    return await _userRepository.authToken;
  }

  // Get current user ID
  Future<int?> getCurrentUserId() async {
    return await _userRepository.userId;
  }

  // Logout
  Future<void> logout() async {
    await _userRepository.logout();
  }
}
