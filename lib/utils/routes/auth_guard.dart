import 'package:flutter/material.dart';
import 'package:boilerplate/utils/security/auth_utils.dart';

class AuthGuard {
  final AuthService _authService;

  AuthGuard(this._authService);

  // Check authentication before navigating to a protected route
  Future<bool> canActivate(BuildContext context) async {
    final isAuth = await _authService.verifyAuthentication();

    if (!isAuth) {
      // Redirect to login
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }

    return true;
  }
}
