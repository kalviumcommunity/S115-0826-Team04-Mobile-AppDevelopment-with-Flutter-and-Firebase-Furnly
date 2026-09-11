import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/conflict_alert.dart';
import '../widgets/loading_indicator.dart';
import 'rental_detail_screen.dart';

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
              tabs: [Tab(text: 'Items'), Tab(text: 'Rentals')],
            ),
            Expanded(
              child: TabBarView(
                children: [_ItemsLiveList(), _RentalsLiveList()],
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
          return const LoadingIndicator(message: 'Loading inventory...');
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
                  color:
                      data['currentStatus'] == 'available'
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

  Map<String, List<String>> _findConflictGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final conflictMap = <String, List<String>>{};

    for (var i = 0; i < docs.length; i++) {
      final first = docs[i].data();
      if (first['actualReturnDate'] != null) continue;

      final firstItems = List<String>.from(first['itemIds'] ?? []);
      final firstStart = (first['startDate'] as Timestamp).toDate();
      final firstEnd = (first['expectedReturnDate'] as Timestamp).toDate();

      for (var j = 0; j < docs.length; j++) {
        if (i == j) continue;

        final second = docs[j].data();
        if (second['actualReturnDate'] != null) continue;

        final secondItems = List<String>.from(second['itemIds'] ?? []);
        final secondStart = (second['startDate'] as Timestamp).toDate();
        final secondEnd = (second['expectedReturnDate'] as Timestamp).toDate();

        final sharedItem = firstItems.any((id) => secondItems.contains(id));
        final overlaps =
            firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);

        if (sharedItem && overlaps) {
          conflictMap.putIfAbsent(docs[i].id, () => []).add(docs[j].id);
        }
      }
    }

    return conflictMap;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('rentals')
              .orderBy('startDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingIndicator(message: 'Loading rentals...');
        }

        final docs = snapshot.data!.docs;
        final conflictGroups = _findConflictGroups(docs);

        return ListView(
          children: [
            ...conflictGroups.entries.map(
              (group) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: ConflictAlert(
                  title: 'Conflict Detected',
                    message: 'Rental ${group.key} conflicts with '
                      '${group.value.join(', ')}.',
                  onReview: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RentalDetailScreen(rentalId: group.key),
                      ),
                    );
                  },
                ),
              ),
            ),
            ...docs.map((doc) {
              final data = doc.data();

              return ListTile(
                title: Text('Customer: ${data['customerId'] ?? ''}'),
                subtitle: Text('Status: ${data['billingStatus'] ?? ''}'),
                trailing: Text('₹${data['computedCharge'] ?? 0}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RentalDetailScreen(rentalId: doc.id),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}
