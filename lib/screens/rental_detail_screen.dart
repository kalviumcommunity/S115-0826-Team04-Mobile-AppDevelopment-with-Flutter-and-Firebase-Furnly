import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_rental_screen.dart';

class RentalDetailScreen extends StatelessWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  Widget _buildTimeToLogMetric(
    Map<String, dynamic> rental,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> events,
  ) {
    final startDate = (rental['startDate'] as Timestamp).toDate();
    final deliveryEvents =
        events.where((event) => event.data()['type'] == 'delivery').toList();

    if (deliveryEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    deliveryEvents.sort((a, b) {
      final aTime =
          (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime =
          (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    final firstLogTime =
        (deliveryEvents.first.data()['timestamp'] as Timestamp?)?.toDate();
    if (firstLogTime == null) {
      return const SizedBox.shrink();
    }

    final gap = firstLogTime.difference(startDate);
    final hours = gap.inHours;
    final minutes = gap.inMinutes % 60;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Delivery logged $hours h $minutes m after rental start',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Detail'),
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('rentals')
                    .doc(rentalId)
                    .snapshots(),
            builder: (context, snapshot) {
              final rental =
                  snapshot.hasData && snapshot.data!.exists
                      ? snapshot.data!.data()!
                      : null;
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed:
                    rental == null
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditRentalScreen(
                                    rentalId: rentalId,
                                    rentalData: rental,
                                  ),
                            ),
                          );
                        },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text('Billing status: ${rental['billingStatus']}'),
              Text('Computed charge: ₹${rental['computedCharge'] ?? 0}'),
              const Divider(height: 32),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance
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
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('No events logged yet.'),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeToLogMetric(rental, events),
                      const SizedBox(height: 12),
                      const Text(
                        'Event History',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...events.map((doc) {
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
                            trailing:
                                data['photoUrl'] != null
                                    ? const Icon(Icons.photo, size: 18)
                                    : null,
                          ),
                        );
                      }),
                    ],
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
