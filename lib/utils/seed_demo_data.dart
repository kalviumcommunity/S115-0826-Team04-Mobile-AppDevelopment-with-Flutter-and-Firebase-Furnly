import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDemoData() async {
  final firestore = FirebaseFirestore.instance;

  final itemRefs = <String>[];

  final items = [
    {'name': '3-Seater Sofa', 'category': 'Living Room'},
    {'name': 'Queen Bed Frame', 'category': 'Bedroom'},
    {'name': 'Dining Table (6 seat)', 'category': 'Dining'},
    {'name': 'Office Chair', 'category': 'Office'},
  ];

  for (final item in items) {
    final doc = await firestore.collection('items').add({
      'name': item['name'],
      'category': item['category'],
      'currentStatus': 'available',
      'currentRentalId': null,
      'lastEventTimestamp': null,
    });
    itemRefs.add(doc.id);
  }

  await firestore.collection('customers').add({
    'name': 'Demo Customer',
    'contact': '9999999999',
    'rentalIds': [],
  });

  await firestore.collection('rentals').add({
    'customerId': 'demo_customer_001',
    'itemIds': [itemRefs[0]],
    'startDate': Timestamp.fromDate(DateTime.now()),
    'expectedReturnDate':
        Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
    'actualReturnDate': null,
    'billingStatus': 'pending',
    'ratePerDay': 150,
    'computedCharge': 0,
  });
}
