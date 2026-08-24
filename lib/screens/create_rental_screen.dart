import 'package:flutter/material.dart';

import '../models/rental_model.dart';
import '../services/rental_service.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() =>
      _CreateRentalScreenState();
}

class _CreateRentalScreenState
    extends State<CreateRentalScreen> {

  final customerController = TextEditingController();
  final itemsController = TextEditingController();
  final rateController = TextEditingController();

  DateTime? startDate;
  DateTime? expectedReturnDate;

  final RentalService rentalService = RentalService();

  bool isLoading = false;

  Future<void> selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        startDate = selected;
      });
    }
  }

  Future<void> selectReturnDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDate: startDate ?? DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        expectedReturnDate = selected;
      });
    }
  }

  Future<void> createRental() async {
    if (customerController.text.trim().isEmpty ||
        itemsController.text.trim().isEmpty ||
        startDate == null ||
        expectedReturnDate == null ||
        rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );

      return;
    }

    final rate = double.tryParse(
      rateController.text.trim(),
    );

    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid rate'),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final rental = RentalModel(
        customerId: customerController.text.trim(),
        itemIds: itemsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        startDate: startDate!,
        expectedReturnDate: expectedReturnDate!,
        ratePerDay: rate,
      );

      await rentalService.createRental(rental);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental created successfully'),
        ),
      );

      customerController.clear();
      itemsController.clear();
      rateController.clear();

      setState(() {
        startDate = null;
        expectedReturnDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create rental'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Rental'),
      ),
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
              title: Text(
                startDate == null
                    ? 'Select Start Date'
                    : 'Start: ${startDate!.day}/${startDate!.month}/${startDate!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: selectStartDate,
            ),

            ListTile(
              title: Text(
                expectedReturnDate == null
                    ? 'Select Expected Return'
                    : 'Return: ${expectedReturnDate!.day}/${expectedReturnDate!.month}/${expectedReturnDate!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: selectReturnDate,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rate per Day',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : createRental,
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
