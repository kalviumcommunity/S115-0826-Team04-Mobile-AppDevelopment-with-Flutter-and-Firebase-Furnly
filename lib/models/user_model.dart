class UserModel {
  final String uid;
  final String role;

  UserModel({
    required this.uid,
    required this.role,
  });

  factory UserModel.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return UserModel(
      uid: uid,
      role: data['role'] ?? 'crew',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
    };
  }
}
