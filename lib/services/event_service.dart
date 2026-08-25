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
  }
}
