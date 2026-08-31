import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import '../services/rental_service.dart';
import '../services/conflict_service.dart';
import '../widgets/conflict_alert.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  final customerController = TextEditingController();
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
    customerController.dispose();
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
    if (customerController.text.trim().isEmpty ||
        itemsController.text.trim().isEmpty ||
        startDate == null ||
        expectedReturnDate == null ||
        rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
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

    final rental = RentalModel(
      customerId: customerController.text.trim(),
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

    customerController.clear();
    itemsController.clear();
    rateController.clear();

    setState(() {
      startDate = null;
      expectedReturnDate = null;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Rental')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: customerController,
              decoration: const InputDecoration(
                labelText: 'Customer ID',
                border: OutlineInputBorder(),
              ),
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
                    'Item already booked under rental ${conflict!['rentalId']}',
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submit,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Rental'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
