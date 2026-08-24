import 'package:cloud_firestore/cloud_firestore.dart';

class QueryService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getAvailableItems() {
    return _firestore
        .collection('items')
        .where(
          'currentStatus',
          isEqualTo: 'available',
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getUpcomingRentals() {
    return _firestore
        .collection('rentals')
        .where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.now(),
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getItemRentals(String itemId) {
    return _firestore
        .collection('rentals')
        .where(
          'itemIds',
          arrayContains: itemId,
        )
        .snapshots();
  }
}
