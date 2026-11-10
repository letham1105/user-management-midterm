
class UserModel {
  final String id;
  final String username;
  final String email;
  final String? imageUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.imageUrl,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return UserModel(
      id: documentId,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'imageUrl': imageUrl,
    };
  }
}
