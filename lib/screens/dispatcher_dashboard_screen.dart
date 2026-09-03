import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/conflict_alert.dart';

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
                  const _ItemsLiveList(),
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

  List<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _findConflicts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final conflicts = <List<QueryDocumentSnapshot<Map<String, dynamic>>>>[];

    for (var i = 0; i < docs.length; i++) {
      final a = docs[i].data();
      if (a['actualReturnDate'] != null) continue;

      final aItems = List<String>.from(a['itemIds'] ?? []);
      final aStart = (a['startDate'] as Timestamp).toDate();
      final aEnd = (a['expectedReturnDate'] as Timestamp).toDate();

      for (var j = i + 1; j < docs.length; j++) {
        final b = docs[j].data();
        if (b['actualReturnDate'] != null) continue;

        final bItems = List<String>.from(b['itemIds'] ?? []);
        final bStart = (b['startDate'] as Timestamp).toDate();
        final bEnd = (b['expectedReturnDate'] as Timestamp).toDate();

        final sharedItem = aItems.any((id) => bItems.contains(id));
        final overlaps = aStart.isBefore(bEnd) && bStart.isBefore(aEnd);

        if (sharedItem && overlaps) {
          conflicts.add([docs[i], docs[j]]);
        }
      }
    }

    return conflicts;
  }

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
        final conflicts = _findConflicts(docs);

        return ListView(
          children: [
            if (conflicts.isNotEmpty)
              ...conflicts.map(
                (pair) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ConflictAlert(
                    title: 'Conflict Detected',
                    message:
                        'Rentals ${pair[0].id} and ${pair[1].id} share an overlapping item and date range.',
                  ),
                ),
              ),
            ...docs.map((doc) {
              final data = doc.data();

              return ListTile(
                title: Text('Customer: ${data['customerId'] ?? ''}'),
                subtitle: Text('Status: ${data['billingStatus'] ?? ''}'),
                trailing: Text('₹${data['computedCharge'] ?? 0}'),
              );
            }),
          ],
        );
      },
    );
  }
}

