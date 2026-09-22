import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rental_detail_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customerName)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rentals')
            .where('customerId', isEqualTo: customerId)
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No rentals for this customer yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return ListTile(
                title: Text('Rental ${docs[index].id.substring(0, 6)}'),
                subtitle: Text('Status: ${data['billingStatus'] ?? ''}'),
                trailing: Text('₹${data['computedCharge'] ?? 0}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RentalDetailScreen(rentalId: docs[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
