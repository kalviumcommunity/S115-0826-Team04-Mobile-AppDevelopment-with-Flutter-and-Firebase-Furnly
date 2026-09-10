import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';
import '../services/rental_service.dart';
import '../services/conflict_service.dart';
import '../widgets/conflict_alert.dart';
import '../widgets/loading_indicator.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  // Customer is now selected from a Firestore-backed dropdown, not free text.
  String? selectedCustomerId;

  final itemsController = TextEditingController();
  final rateController = TextEditingController();

  DateTime? startDate;
  DateTime? expectedReturnDate;

  final RentalService rentalService = RentalService();
  final ConflictService conflictService = ConflictService();

  bool isLoading = false;
  Map<String, dynamic>? conflict;

  @override
  void dispose() {
    itemsController.dispose();
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
    // Validate: selectedCustomerId replaces customerController.text
    if (selectedCustomerId == null ||
        itemsController.text.trim().isEmpty ||
        startDate == null ||
        expectedReturnDate == null ||
        rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
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

    final itemIds = itemsController.text
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    for (final itemId in itemIds) {
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

    // Pass selectedCustomerId! — now a real Firestore document ID.
    final rental = RentalModel(
      customerId: selectedCustomerId!,
      itemIds: itemIds,
      startDate: startDate!,
      expectedReturnDate: expectedReturnDate!,
      ratePerDay: double.tryParse(rateController.text.trim()) ?? 0,
    );

    await rentalService.createRental(rental);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rental created successfully')),
    );

    itemsController.clear();
    rateController.clear();

    setState(() {
      selectedCustomerId = null;
      startDate = null;
      expectedReturnDate = null;
      isLoading = false;
    });
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
            children: [
              // ── Customer Dropdown (replaces free-text Customer ID field) ──
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('customers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              TextField(
                controller: itemsController,
                decoration: const InputDecoration(
                  labelText: 'Item IDs (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(startDate == null
                    ? 'Select start date'
                    : 'Start: ${startDate!.day}/${startDate!.month}/${startDate!.year}'),
                onTap: pickStart,
              ),
              ListTile(
                title: Text(expectedReturnDate == null
                    ? 'Select return date'
                    : 'Return: ${expectedReturnDate!.day}/${expectedReturnDate!.month}/${expectedReturnDate!.year}'),
                onTap: pickReturn,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate per day',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (conflict != null)
                ConflictAlert(
                  title: 'Conflict Detected',
                  message:
                      'Item already booked under rental ${conflict!["rentalId"]}',
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const LoadingIndicator(message: 'Submitting...')
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
