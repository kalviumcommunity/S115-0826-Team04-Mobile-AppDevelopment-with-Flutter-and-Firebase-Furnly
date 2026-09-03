import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DispatcherDashboardScreen extends StatelessWidget {
  const DispatcherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispatcher Dashboard')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.black,
              tabs: [
                Tab(text: 'Items'),
                Tab(text: 'Rentals'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ItemsLiveList(),
                  _RentalsLiveList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsLiveList extends StatelessWidget {
  const _ItemsLiveList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            return ListTile(
              title: Text(data['name'] ?? ''),
              subtitle: Text(data['category'] ?? ''),
              trailing: Text(
                data['currentStatus'] ?? '',
                style: TextStyle(
                  color: data['currentStatus'] == 'available'
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RentalsLiveList extends StatelessWidget {
  const _RentalsLiveList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rentals')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            return ListTile(
              title: Text('Customer: ${data['customerId'] ?? ''}'),
              subtitle: Text('Status: ${data['billingStatus'] ?? ''}'),
              trailing: Text('₹${data['computedCharge'] ?? 0}'),
            );
          },
        );
      },
    );
  }
}
