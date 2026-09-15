import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> logEvent(EventModel event, {File? photo}) async {
    final docRef = _firestore.collection('events').doc();

    // Fire and forget Firestore writes so they queue gracefully offline.
    // Awaiting them would block indefinitely without a connection.
    docRef.set({
      ...event.toMap(),
      'photoUrl': null,
    });

    _firestore.collection('items').doc(event.itemId).update({
      'currentStatus': event.type == 'pickup' ? 'available' : 'out',
      'lastEventTimestamp': FieldValue.serverTimestamp(),
    });

    if (event.type == 'pickup') {
      _applyBilling(event.rentalId);
    }

    if (photo != null) {
      try {
        final ref = _storage.ref().child('event_photos/${docRef.id}.jpg');
        // This will throw if offline, but the event is already queued above.
        await ref.putFile(photo);
        final photoUrl = await ref.getDownloadURL();
        await docRef.update({'photoUrl': photoUrl});
      } catch (e) {
        // Photo upload failed (e.g. offline), but the event was logged.
      }
    }
  }

  Future<void> _applyBilling(String rentalId) async {
    final rentalRef = _firestore.collection('rentals').doc(rentalId);
    final rentalDoc = await rentalRef.get();

    if (!rentalDoc.exists) return;

    final data = rentalDoc.data()!;
    final startDate = (data['startDate'] as Timestamp).toDate();
    final ratePerDay = (data['ratePerDay'] ?? 0).toDouble();
    final itemCount = (data['itemIds'] as List).length;

    final now = DateTime.now();
    final days = now.difference(startDate).inDays;
    final safeDays = days < 1 ? 1 : days;

    await rentalRef.update({
      'actualReturnDate': Timestamp.fromDate(now),
      'billingStatus': 'completed',
      'computedCharge': safeDays * ratePerDay * itemCount,
    });
  }
}
