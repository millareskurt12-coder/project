class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
  });

  final int id;
  final String fullName;
  final String username;

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
    );
  }
}
