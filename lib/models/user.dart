class User {
  final int? id;
  final String username;
  final String password;
  final String permission; // 'admin' | 'operator'

  const User({
    this.id,
    required this.username,
    required this.password,
    this.permission = 'operator',
  });

  bool get isAdmin => permission == 'admin';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password': password,
      'permission': permission,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      permission: map['permission'] as String,
    );
  }
}
