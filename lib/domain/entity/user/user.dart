class User {
  final int id;
  final String email;
  final String password;
  final String token;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.token,
  });

  /// Membuat instance [User] dari [Map] (misalnya dari JSON).
  factory User.fromMap(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      password: json['password'] as String,
      token: json['token'] as String,
    );
  }

  /// Mengubah instance [User] menjadi [Map] untuk keperluan serialisasi.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'token': token,
    };
  }
}
