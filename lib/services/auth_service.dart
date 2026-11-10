
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String adminEmail = 'letham10122005@gmail.com';

  User? get currentUser => _auth.currentUser;

  // Check whether the signed-in account is Admin.
  bool get isAdmin {
    final email = _auth.currentUser?.email;
    return email?.toLowerCase() == adminEmail.toLowerCase();
  }

  // Register
  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  // Login
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  // Forgot password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Password reset failed');
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
