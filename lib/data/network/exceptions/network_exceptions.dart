class NetworkException implements Exception {
  String? message;
  int? statusCode;

  NetworkException({this.message, this.statusCode});
}

class AuthException extends NetworkException {
  // ignore: use_super_parameters
  AuthException({message, statusCode})
      : super(message: message, statusCode: statusCode);
}
