import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';

class RentalService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> createRental(RentalModel rental) async {
    final document =
        await _firestore.collection('rentals').add(
              rental.toMap(),
            );

    return document.id;
  }

  Future<void> updateRentalDates({
    required String rentalId,
    required DateTime startDate,
    required DateTime expectedReturnDate,
    required double ratePerDay,
  }) async {
    await _firestore.collection('rentals').doc(rentalId).update({
      'startDate': Timestamp.fromDate(startDate),
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'ratePerDay': ratePerDay,
    });
  }
}
