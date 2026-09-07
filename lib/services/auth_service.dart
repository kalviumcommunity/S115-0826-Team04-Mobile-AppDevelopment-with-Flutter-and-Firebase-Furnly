import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user;
  }

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': 'crew',
      });
    }

    return credential.user;
  }

  Future<String?> getUserRole(String uid) async {
    final document =
        await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    return data?['role'];
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
