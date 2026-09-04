import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../widgets/error_banner.dart';

class LogEventScreen extends StatefulWidget {
  const LogEventScreen({super.key});

  @override
  State<LogEventScreen> createState() => _LogEventScreenState();
}

class _LogEventScreenState extends State<LogEventScreen> {
  final itemIdController = TextEditingController();
  final rentalIdController = TextEditingController();
  final notesController = TextEditingController();

  String selectedType = 'delivery';
  File? selectedPhoto;
  bool isLoading = false;
  String? errorMessage;

  final EventService eventService = EventService();
  final ImagePicker picker = ImagePicker();

  Future<void> pickPhoto() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        selectedPhoto = File(picked.path);
      });
    }
  }

  Future<void> submitEvent() async {
    if (itemIdController.text.trim().isEmpty ||
        rentalIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item ID and Rental ID are required')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final event = EventModel(
        itemId: itemIdController.text.trim(),
        rentalId: rentalIdController.text.trim(),
        crewId: uid,
        type: selectedType,
        notes: notesController.text.trim(),
      );

      await eventService.logEvent(event, photo: selectedPhoto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event logged successfully')),
      );

      itemIdController.clear();
      rentalIdController.clear();
      notesController.clear();

      setState(() {
        selectedPhoto = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to log event.';
      });
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
      appBar: AppBar(title: const Text('Log Delivery / Pickup')),
      body: SingleChildScrollView(
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
            TextField(
              controller: rentalIdController,
              decoration: const InputDecoration(
                labelText: 'Rental ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                DropdownMenuItem(
                  value: 'damage_reported',
                  child: Text('Damage Reported'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedType = value ?? 'delivery';
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: pickPhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(selectedPhoto == null ? 'Add photo' : 'Photo added'),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null) ErrorBanner(message: errorMessage!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitEvent,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Log Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
