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
      DateTime existingEnd = (data['expectedReturnDate'] as Timestamp).toDate();

      // If the rental is overdue but not returned, it is effectively still 
      // occupying the item at least until now.
      if (existingEnd.isBefore(DateTime.now())) {
        existingEnd = DateTime.now().add(const Duration(minutes: 5));
      }

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
