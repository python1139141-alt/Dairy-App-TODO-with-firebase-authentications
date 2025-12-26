import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Signup with email & password
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message; // show error
    }
  }

  /// ✅ Login with email & password
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// ✅ Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ✅ Current user stream (for auto-login check)
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// ✅ Get current user
  User? get currentUser => _auth.currentUser;
}
