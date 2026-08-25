import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String itemId;
  final String rentalId;
  final String crewId;
  final String type;
  final String? notes;

  EventModel({
    required this.itemId,
    required this.rentalId,
    required this.crewId,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'rentalId': rentalId,
      'crewId': crewId,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes,
    };
  }
}
