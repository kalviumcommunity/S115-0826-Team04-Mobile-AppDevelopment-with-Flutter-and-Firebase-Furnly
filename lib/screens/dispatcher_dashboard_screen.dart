import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/seed_demo_data.dart';
import '../widgets/conflict_alert.dart';
import '../widgets/loading_indicator.dart';
import 'create_rental_screen.dart';
import 'customer_list_screen.dart';
import 'inventory_list_screen.dart';
import 'login_screen.dart';
import 'rental_detail_screen.dart';

class DispatcherDashboardScreen extends StatelessWidget {
  const DispatcherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Furnly Dashboard'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Items'), Tab(text: 'Rentals')],
          ),
          actions: [
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.chair_alt_rounded, size: 40),
                      SizedBox(height: 8),
                      Text('Furnly',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Operations'),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InventoryListScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Customers'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerListScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box_outlined),
                  title: const Text('Create Rental'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateRentalScreen()),
                    );
                  },
                ),
                if (uid != null)
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get(),
                    builder: (context, snapshot) {
                      final role = snapshot.data?.data()?['role'];
                      if (role != 'admin') return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.dataset_outlined),
                            title: const Text('Seed Demo Data'),
                            subtitle: const Text(
                                'Adds sample items, customers, rentals'),
                            onTap: () async {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Seeding demo data...')),
                              );
                              try {
                                await seedDemoData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Demo data added successfully')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to seed data: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateRentalScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Rental'),
        ),
        body: Column(
          children: [
            const _SummaryStatsRow(),
            const Expanded(
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

class _SummaryStatsRow extends StatelessWidget {
  const _SummaryStatsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  _StatChip(
                      label: 'Items', value: '$totalItems', icon: Icons.chair),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Out',
                      value: '$outItems',
                      icon: Icons.local_shipping_outlined),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Active rentals',
                      value: '$activeRentals',
                      icon: Icons.receipt_long_outlined),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No items yet',
            subtitle: 'Add items from the Inventory screen in the menu.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final status = data['currentStatus'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                  child: Icon(Icons.chair_alt_outlined,
                      color: _statusColor(status)),
                ),
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['category'] ?? ''),
                trailing: Chip(
                  label: Text(status,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                  labelStyle: TextStyle(color: _statusColor(status)),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green.shade700;
      case 'maintenance':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }
}

class _RentalsLiveList extends StatefulWidget {
  const _RentalsLiveList();

  @override
  State<_RentalsLiveList> createState() => _RentalsLiveListState();
}

class _RentalsLiveListState extends State<_RentalsLiveList> {
  String filter = 'all';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
            stream: FirebaseFirestore.instance
                .collection('rentals')
                .orderBy('startDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingIndicator(message: 'Loading rentals...');
              }

              final allDocs = snapshot.data!.docs;
              final conflictGroups = _findConflictGroups(allDocs);

              var docs = allDocs;

              if (filter != 'all') {
                docs = docs.where((doc) {
                  final data = doc.data();
                  return data['billingStatus'] == filter;
                }).toList();
              }

              if (allDocs.isEmpty) {
                return const _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No rentals yet',
                  subtitle: 'Tap "New Rental" to create your first one.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    ...conflictGroups.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ConflictAlert(
                          title: 'Conflict Detected',
                          message: entry.value.length == 1
                              ? 'This rental overlaps with rental ${entry.value.first.substring(0, 6)} on a shared item.'
                              : 'This rental overlaps with ${entry.value.length} other rentals on a shared item.',
                          onReview: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RentalDetailScreen(rentalId: entry.key),
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
                        final billingStatus =
                            data['billingStatus'] as String? ?? '';

                        return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>?>(
                          future: customerId.isEmpty
                              ? Future<DocumentSnapshot<Map<String, dynamic>>?>
                                  .value(null)
                              : FirebaseFirestore.instance
                                  .collection('customers')
                                  .doc(customerId)
                                  .get(),
                          builder: (context, customerSnap) {
                            final customerName = customerSnap.hasData &&
                                    customerSnap.data != null &&
                                    customerSnap.data!.exists
                                ? (customerSnap.data!.data()?['name'] ??
                                    customerId)
                                : customerId;

                            final hasConflict =
                                conflictGroups.containsKey(doc.id);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasConflict
                                    ? Colors.deepOrange.withOpacity(0.15)
                                    : billingStatus == 'completed'
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.blue.withOpacity(0.15),
                                child: Icon(
                                  hasConflict
                                      ? Icons.warning_amber_rounded
                                      : billingStatus == 'completed'
                                          ? Icons.check_circle_outline
                                          : Icons.schedule,
                                  color: hasConflict
                                      ? Colors.deepOrange
                                      : billingStatus == 'completed'
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                ),
                              ),
                              title: Text(customerName),
                              subtitle:
                                  Text('Status: ${billingStatus.isEmpty ? "pending" : billingStatus}'),
                              trailing: Text('₹${data['computedCharge'] ?? 0}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RentalDetailScreen(rentalId: doc.id),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
