import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .get();
  }
}
