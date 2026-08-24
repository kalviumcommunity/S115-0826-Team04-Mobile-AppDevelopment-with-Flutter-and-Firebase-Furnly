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
}
