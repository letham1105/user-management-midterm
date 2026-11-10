
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // Save profile after registration.
  // Document ID = Firebase Authentication UID.
  Future<void> saveUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _users.doc(userId).set(data, SetOptions(merge: true));
  }

  // Get current user's profile.
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // Add user profile.
  Future<void> addUser(UserModel user) async {
    if (user.id.isEmpty) {
      throw Exception('User ID cannot be empty.');
    }

    await _users.doc(user.id).set(user.toMap());
  }

  // Update user profile.
  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).update(user.toMap());
  }

  // Delete user profile.
  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  Future<void> updateProfileImage(
    String userId,
    String imageUrl,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'imageUrl': imageUrl,
    });
  }


  // Get all users (Admin access only).
  Stream<List<UserModel>> getUsers() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
