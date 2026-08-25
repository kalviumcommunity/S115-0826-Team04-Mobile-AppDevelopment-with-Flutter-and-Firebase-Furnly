import 'package:cloud_firestore/cloud_firestore.dart';

class ConflictService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> checkConflict({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection('rentals')
        .where('itemIds', arrayContains: itemId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['actualReturnDate'] != null) continue;

      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['expectedReturnDate'] as Timestamp).toDate();

      final overlaps =
          existingStart.isBefore(endDate) && startDate.isBefore(existingEnd);

      if (overlaps) {
        return {
          'rentalId': doc.id,
          'startDate': existingStart,
          'endDate': existingEnd,
        };
      }
    }

    return null;
  }
}
