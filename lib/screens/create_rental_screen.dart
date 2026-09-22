import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';
import '../services/rental_service.dart';
import '../services/conflict_service.dart';
import '../widgets/conflict_alert.dart';
import 'customer_list_screen.dart';
import 'inventory_list_screen.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  String? selectedCustomerId;
  final Set<String> selectedItemIds = {};
  final rateController = TextEditingController();

  DateTime? startDate;
  DateTime? expectedReturnDate;

  final RentalService rentalService = RentalService();
  final ConflictService conflictService = ConflictService();

  bool isLoading = false;
  Map<String, dynamic>? conflict;

  @override
  void dispose() {
    rateController.dispose();
    super.dispose();
  }

  Future<void> pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickReturn() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: startDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => expectedReturnDate = picked);
  }

  Future<void> submit() async {
    if (selectedCustomerId == null ||
        selectedItemIds.isEmpty ||
        startDate == null ||
        expectedReturnDate == null ||
        rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and select at least one item')),
      );
      return;
    }

    if (expectedReturnDate!.isBefore(startDate!) ||
        expectedReturnDate!.isAtSameMomentAs(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return date must be after start date')),
      );
      return;
    }

    final rate = double.tryParse(rateController.text.trim());

    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid rate greater than 0')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      conflict = null;
    });

    for (final itemId in selectedItemIds) {
      final result = await conflictService.checkConflict(
        itemId: itemId,
        startDate: startDate!,
        endDate: expectedReturnDate!,
      );

      if (result != null) {
        setState(() {
          conflict = result;
          isLoading = false;
        });
        return;
      }
    }

    final rental = RentalModel(
      customerId: selectedCustomerId!,
      itemIds: selectedItemIds.toList(),
      startDate: startDate!,
      expectedReturnDate: expectedReturnDate!,
      ratePerDay: rate,
    );

    await rentalService.createRental(rental);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rental created successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Rental')),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance.collection('customers').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final customers = snapshot.data!.docs;

                  if (customers.isEmpty) {
                    return _EmptyLinkCard(
                      message: 'No customers yet.',
                      actionLabel: 'Add a customer',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerListScreen()),
                        );
                      },
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: selectedCustomerId,
                    decoration: const InputDecoration(
                      hintText: 'Select a customer',
                    ),
                    items: customers.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unnamed'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCustomerId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Items', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance.collection('items').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final items = snapshot.data!.docs;

                  if (items.isEmpty) {
                    return _EmptyLinkCard(
                      message: 'No items in inventory yet.',
                      actionLabel: 'Add an item',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryListScreen()),
                        );
                      },
                    );
                  }

                  return Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: items.map((doc) {
                        final data = doc.data();
                        final isSelected = selectedItemIds.contains(doc.id);

                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(data['name'] ?? ''),
                          subtitle: Text(
                              '${data['category'] ?? ''} · ${data['currentStatus'] ?? ''}'),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedItemIds.add(doc.id);
                              } else {
                                selectedItemIds.remove(doc.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Dates & rate', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: pickStart,
                      label: Text(startDate == null
                          ? 'Start date'
                          : '${startDate!.day}/${startDate!.month}/${startDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: pickReturn,
                      label: Text(expectedReturnDate == null
                          ? 'Return date'
                          : '${expectedReturnDate!.day}/${expectedReturnDate!.month}/${expectedReturnDate!.year}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate per day (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 20),
              if (conflict != null)
                ConflictAlert(
                  title: 'Conflict Detected',
                  message:
                      'One of the selected items is already booked under rental ${conflict!["rentalId"].toString().substring(0, 6)} for an overlapping date range.',
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Rental'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLinkCard extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const _EmptyLinkCard({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
