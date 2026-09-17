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
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('items').snapshots(),
              builder: (context, itemsSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('rentals')
                      .where('billingStatus', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, rentalsSnapshot) {
                    final totalItems = itemsSnapshot.data?.docs.length ?? 0;
                    final outItems = itemsSnapshot.data?.docs.where((doc) {
                          final data = doc.data();
                          return data['currentStatus'] == 'out';
                        }).length ??
                        0;
                    final activeRentals = rentalsSnapshot.data?.docs.length ?? 0;

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _StatChip(label: 'Items', value: '$totalItems'),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Out', value: '$outItems'),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Active rentals', value: '$activeRentals'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
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

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
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
          ),
        );
      },
    );
  }
}

class _RentalsLiveList extends StatefulWidget {
  const _RentalsLiveList();

  @override
  State<_RentalsLiveList> createState() => _RentalsLiveListState();
}

class _RentalsLiveListState extends State<_RentalsLiveList> {
  String filter = 'all';

  List<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _findConflicts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final conflicts = <List<QueryDocumentSnapshot<Map<String, dynamic>>>>[];

    for (var i = 0; i < docs.length; i++) {
      final first = docs[i].data();
      if (first['actualReturnDate'] != null) continue;

      final firstItems = List<String>.from(first['itemIds'] ?? []);
      final firstStart = (first['startDate'] as Timestamp).toDate();
      final firstEnd = (first['expectedReturnDate'] as Timestamp).toDate();

      for (var j = i + 1; j < docs.length; j++) {
        final second = docs[j].data();
        if (second['actualReturnDate'] != null) continue;

        final secondItems = List<String>.from(second['itemIds'] ?? []);
        final secondStart = (second['startDate'] as Timestamp).toDate();
        final secondEnd = (second['expectedReturnDate'] as Timestamp).toDate();

        final sharedItem = firstItems.any((id) => secondItems.contains(id));
        final overlaps =
            firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);

        if (sharedItem && overlaps) {
          conflicts.add([docs[i], docs[j]]);
        }
      }
    }

    return conflicts;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: filter == 'all',
                onSelected: (_) => setState(() => filter = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Active'),
                selected: filter == 'pending',
                onSelected: (_) => setState(() => filter = 'pending'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Completed'),
                selected: filter == 'completed',
                onSelected: (_) => setState(() => filter = 'completed'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('rentals')
                    .orderBy('startDate', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingIndicator(message: 'Loading rentals...');
              }

              final allDocs = snapshot.data!.docs;
              final conflicts = _findConflicts(allDocs);

              var docs = allDocs;

              if (filter != 'all') {
                docs = docs.where((doc) {
                  final data = doc.data();
                  return data['billingStatus'] == filter;
                }).toList();
              }

              if (conflicts.isEmpty && docs.isEmpty) {
                return const Center(child: Text('No rentals in this view.'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  children: [
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
                          onReview: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        RentalDetailScreen(rentalId: pair[0].id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No rentals in this view.')),
                      )
                    else
                      ...docs.map((doc) {
                        final data = doc.data();
                        final customerId = data['customerId'] as String? ?? '';

                        return FutureBuilder<
                          DocumentSnapshot<Map<String, dynamic>>?
                        >(
                          future:
                              customerId.isEmpty
                                  ? Future<
                                    DocumentSnapshot<
                                      Map<String, dynamic>
                                    >?
                                  >.value(null)
                                  : FirebaseFirestore.instance
                                      .collection('customers')
                                      .doc(customerId)
                                      .get(),
                          builder: (context, customerSnap) {
                            final customerName =
                                customerSnap.hasData &&
                                        customerSnap.data != null &&
                                        customerSnap.data!.exists
                                    ? (customerSnap.data!.data()?['name'] ??
                                        customerId)
                                    : customerId;

                            return ListTile(
                              title: Text('Customer: $customerName'),
                              subtitle: Text(
                                'Status: ${data['billingStatus'] ?? ''}',
                              ),
                              trailing: Text('₹${data['computedCharge'] ?? 0}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => RentalDetailScreen(
                                          rentalId: doc.id,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
