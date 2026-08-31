import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logEvent(EventModel event) async {
    await _firestore.collection('events').add(event.toMap());

    await _firestore.collection('items').doc(event.itemId).update({
      'currentStatus': event.type == 'pickup' ? 'available' : 'out',
      'lastEventTimestamp': FieldValue.serverTimestamp(),
    });

    if (event.type == 'pickup') {
      await _applyBilling(event.rentalId);
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

    final computedCharge = safeDays * ratePerDay * itemCount;

    await rentalRef.update({
      'actualReturnDate': Timestamp.fromDate(now),
      'billingStatus': 'completed',
      'computedCharge': computedCharge,
    });
  }
}
