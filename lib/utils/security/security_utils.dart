import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';

class SecurityUtils {
  // Secret key for JWT signing - in a real app, store this securely
  static const String _jwtSecret = 'your_jwt_secret_key';

  // Hash password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate JWT token
  static String generateJwtToken(int userId, String email) {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 7)); // Token expires in 7 days

    final payload = {
      'sub': userId.toString(),
      'email': email,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    };

    // In a real implementation, we'd use a proper JWT library for encoding
    // This is a simplified version
    final encodedHeader = base64Url
        .encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})));

    final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));

    final signatureInput = '$encodedHeader.$encodedPayload';
    final signatureBytes = utf8.encode(signatureInput + _jwtSecret);
    final signature = base64Url.encode(sha256.convert(signatureBytes).bytes);

    return '$encodedHeader.$encodedPayload.$signature';
  }

  // Verify JWT token
  static bool verifyToken(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiryTime = decodedToken['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return expiryTime > currentTime;
    } catch (e) {
      return false;
    }
  }

  // Generate a unique ID
  static int generateUniqueId() {
    final uuid = const Uuid().v4();
    // Convert UUID to integer (simplified for example)
    return uuid.hashCode.abs();
  }
}
