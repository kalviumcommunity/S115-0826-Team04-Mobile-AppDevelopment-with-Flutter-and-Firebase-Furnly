import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds a richer demo dataset for walkthrough testing.
/// Adds 3 named customers, 4 furniture items, and 4 completed/active rentals
/// with realistic billing numbers.
Future<void> seedDemoData() async {
  final firestore = FirebaseFirestore.instance;

  // ── Items ──────────────────────────────────────────────────────────────────
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

  // ── Customers ──────────────────────────────────────────────────────────────
  final customer1 = await firestore.collection('customers').add({
    'name': 'Priya Sharma',
    'contact': '9876543210',
    'rentalIds': [],
  });

  final customer2 = await firestore.collection('customers').add({
    'name': 'Rahul Mehta',
    'contact': '9123456780',
    'rentalIds': [],
  });

  final customer3 = await firestore.collection('customers').add({
    'name': 'Aisha Khan',
    'contact': '9988776655',
    'rentalIds': [],
  });

  // ── Rentals ────────────────────────────────────────────────────────────────
  final now = DateTime.now();

  // Rental 1 – Priya, completed, sofa for 10 days @ ₹200/day = ₹2000
  final rental1Start = now.subtract(const Duration(days: 20));
  final rental1Return = rental1Start.add(const Duration(days: 10));
  final r1 = await firestore.collection('rentals').add({
    'customerId': customer1.id,
    'itemIds': [itemRefs[0]],
    'startDate': Timestamp.fromDate(rental1Start),
    'expectedReturnDate': Timestamp.fromDate(rental1Return),
    'actualReturnDate': Timestamp.fromDate(rental1Return),
    'billingStatus': 'paid',
    'ratePerDay': 200,
    'computedCharge': 2000,
  });

  // Rental 2 – Rahul, completed, bed frame for 7 days @ ₹350/day = ₹2450
  final rental2Start = now.subtract(const Duration(days: 15));
  final rental2Return = rental2Start.add(const Duration(days: 7));
  final r2 = await firestore.collection('rentals').add({
    'customerId': customer2.id,
    'itemIds': [itemRefs[1]],
    'startDate': Timestamp.fromDate(rental2Start),
    'expectedReturnDate': Timestamp.fromDate(rental2Return),
    'actualReturnDate': Timestamp.fromDate(rental2Return),
    'billingStatus': 'paid',
    'ratePerDay': 350,
    'computedCharge': 2450,
  });

  // Rental 3 – Aisha, active, dining table + office chair for 14 days @ ₹500/day
  final rental3Start = now.subtract(const Duration(days: 5));
  final rental3Expected = rental3Start.add(const Duration(days: 14));
  final r3 = await firestore.collection('rentals').add({
    'customerId': customer3.id,
    'itemIds': [itemRefs[2], itemRefs[3]],
    'startDate': Timestamp.fromDate(rental3Start),
    'expectedReturnDate': Timestamp.fromDate(rental3Expected),
    'actualReturnDate': null,
    'billingStatus': 'pending',
    'ratePerDay': 500,
    'computedCharge': 0,
  });

  // Rental 4 – Priya, upcoming, office chair for 5 days @ ₹150/day
  final rental4Start = now.add(const Duration(days: 3));
  final rental4Expected = rental4Start.add(const Duration(days: 5));
  final r4 = await firestore.collection('rentals').add({
    'customerId': customer1.id,
    'itemIds': [itemRefs[3]],
    'startDate': Timestamp.fromDate(rental4Start),
    'expectedReturnDate': Timestamp.fromDate(rental4Expected),
    'actualReturnDate': null,
    'billingStatus': 'pending',
    'ratePerDay': 150,
    'computedCharge': 0,
  });

  // Back-fill rentalIds on customer docs for completeness
  await customer1.update({
    'rentalIds': [r1.id, r4.id],
  });
  await customer2.update({
    'rentalIds': [r2.id],
  });
  await customer3.update({
    'rentalIds': [r3.id],
  });
}
