import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/rental_service.dart';

class EditRentalScreen extends StatefulWidget {
  final String rentalId;
  final Map<String, dynamic> rentalData;

  const EditRentalScreen({
    super.key,
    required this.rentalId,
    required this.rentalData,
  });

  @override
  State<EditRentalScreen> createState() => _EditRentalScreenState();
}

class _EditRentalScreenState extends State<EditRentalScreen> {
  late DateTime startDate;
  late DateTime expectedReturnDate;
  late TextEditingController rateController;

  final rentalService = RentalService();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    startDate = (widget.rentalData['startDate'] as Timestamp).toDate();
    expectedReturnDate =
        (widget.rentalData['expectedReturnDate'] as Timestamp).toDate();
    rateController = TextEditingController(
      text: (widget.rentalData['ratePerDay'] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    rateController.dispose();
    super.dispose();
  }

  Future<void> pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: startDate,
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickReturn() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: expectedReturnDate,
    );
    if (picked != null) setState(() => expectedReturnDate = picked);
  }

  Future<void> save() async {
    setState(() => isSaving = true);

    await rentalService.updateRentalDates(
      rentalId: widget.rentalId,
      startDate: startDate,
      expectedReturnDate: expectedReturnDate,
      ratePerDay: double.tryParse(rateController.text.trim()) ?? 0,
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Rental')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Start: ${startDate.day}/${startDate.month}/${startDate.year}',
              ),
              onTap: pickStart,
            ),
            ListTile(
              title: Text(
                'Return: ${expectedReturnDate.day}/${expectedReturnDate.month}/${expectedReturnDate.year}',
              ),
              onTap: pickReturn,
            ),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate per day'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : save,
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
