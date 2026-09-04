import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalDetailScreen extends StatelessWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Detail')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rentals')
            .doc(rentalId)
            .snapshots(),
        builder: (context, rentalSnapshot) {
          if (!rentalSnapshot.hasData || !rentalSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final rental = rentalSnapshot.data!.data()!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Customer: ${rental['customerId']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text('Billing status: ${rental['billingStatus']}'),
              Text('Computed charge: ₹${rental['computedCharge'] ?? 0}'),
              const Divider(height: 32),
              const Text(
                'Event History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('rentalId', isEqualTo: rentalId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  if (!eventSnapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final events = eventSnapshot.data!.docs;

                  if (events.isEmpty) {
                    return const Text('No events logged yet.');
                  }

                  return Column(
                    children: events.map((doc) {
                      final data = doc.data();
                      final ts = (data['timestamp'] as Timestamp?)?.toDate();

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            data['type'] == 'pickup'
                                ? Icons.local_shipping
                                : Icons.inventory,
                          ),
                          title: Text(data['type'] ?? ''),
                          subtitle: Text(
                            ts != null ? ts.toString() : 'Unknown time',
                          ),
                          trailing: data['photoUrl'] != null
                              ? const Icon(Icons.photo, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
