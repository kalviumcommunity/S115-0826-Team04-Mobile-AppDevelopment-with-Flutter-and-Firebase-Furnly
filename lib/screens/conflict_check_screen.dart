import 'package:flutter/material.dart';
import '../services/conflict_service.dart';
import '../widgets/conflict_alert.dart';

class ConflictCheckScreen extends StatefulWidget {
  const ConflictCheckScreen({super.key});

  @override
  State<ConflictCheckScreen> createState() => _ConflictCheckScreenState();
}

class _ConflictCheckScreenState extends State<ConflictCheckScreen> {
  final itemIdController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  final ConflictService conflictService = ConflictService();
  Map<String, dynamic>? conflict;
  bool isChecking = false;
  bool hasChecked = false;

  Future<void> pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: startDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> runCheck() async {
    if (itemIdController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      return;
    }

    setState(() {
      isChecking = true;
    });

    final result = await conflictService.checkConflict(
      itemId: itemIdController.text.trim(),
      startDate: startDate!,
      endDate: endDate!,
    );

    setState(() {
      conflict = result;
      isChecking = false;
      hasChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conflict Check')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: itemIdController,
              decoration: const InputDecoration(
                labelText: 'Item ID',
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
              title: Text(endDate == null
                  ? 'Select end date'
                  : 'End: ${endDate!.day}/${endDate!.month}/${endDate!.year}'),
              onTap: pickEnd,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isChecking ? null : runCheck,
              child: isChecking
                  ? const CircularProgressIndicator()
                  : const Text('Check Conflict'),
            ),
            const SizedBox(height: 20),
            if (conflict != null)
              ConflictAlert(
                title: 'Conflict Detected',
                message:
                    'Item already booked under rental ${conflict!['rentalId']}',
              )
            else if (hasChecked && !isChecking)
              const Text('No conflict found'),
          ],
        ),
      ),
    );
  }
}
