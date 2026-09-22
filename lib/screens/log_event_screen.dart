import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../widgets/error_banner.dart';

class LogEventScreen extends StatefulWidget {
  const LogEventScreen({super.key});

  @override
  State<LogEventScreen> createState() => _LogEventScreenState();
}

class _LogEventScreenState extends State<LogEventScreen> {
  final notesController = TextEditingController();

  String? selectedRentalId;
  String? selectedItemId;
  List<String> itemIdsForSelectedRental = [];

  String selectedType = 'delivery';
  File? selectedPhoto;
  bool isLoading = false;
  bool isOffline = false;
  String? errorMessage;
  StreamSubscription<void>? snapshotsInSyncSubscription;

  final EventService eventService = EventService();
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    snapshotsInSyncSubscription =
        FirebaseFirestore.instance.snapshotsInSync().listen((_) {});
    _checkConnection();
  }

  void _checkConnection() {
    FirebaseFirestore.instance
        .collection('items')
        .limit(1)
        .get(const GetOptions(source: Source.server))
        .then((_) {
      if (mounted) setState(() => isOffline = false);
    }).catchError((_) {
      if (mounted) setState(() => isOffline = true);
    });
  }

  @override
  void dispose() {
    snapshotsInSyncSubscription?.cancel();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        selectedPhoto = File(picked.path);
      });
    }
  }

  Future<void> submitEvent() async {
    if (selectedRentalId == null || selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a rental and an item')),
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
        itemId: selectedItemId!,
        rentalId: selectedRentalId!,
        crewId: uid,
        type: selectedType,
        notes: notesController.text.trim(),
      );

      await eventService.logEvent(event, photo: selectedPhoto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event logged successfully')),
      );

      notesController.clear();

      setState(() {
        selectedRentalId = null;
        selectedItemId = null;
        itemIdsForSelectedRental = [];
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
      body: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off, size: 18, color: Colors.black87),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline — this event will sync once you reconnect',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              Text('Rental', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('rentals')
                    .where('billingStatus', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final rentals = snapshot.data!.docs;

                  if (rentals.isEmpty) {
                    return const Text(
                      'No active rentals to log against right now.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  return FutureBuilder<List<_RentalOption>>(
                    future: _loadRentalOptions(rentals),
                    builder: (context, optionsSnapshot) {
                      if (!optionsSnapshot.hasData) {
                        return const LinearProgressIndicator();
                      }

                      final options = optionsSnapshot.data!;

                      return DropdownButtonFormField<String>(
                        initialValue: selectedRentalId,
                        decoration: const InputDecoration(
                          hintText: 'Select a rental',
                        ),
                        items: options.map((option) {
                          return DropdownMenuItem<String>(
                            value: option.rentalId,
                            child: Text(option.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          final matched = options.firstWhere(
                            (option) => option.rentalId == value,
                          );

                          setState(() {
                            selectedRentalId = value;
                            itemIdsForSelectedRental = matched.itemIds;
                            selectedItemId = null;
                          });
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Text('Item', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (selectedRentalId == null)
                const Text(
                  'Select a rental first.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance.collection('items').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }

                    final items = snapshot.data!.docs
                        .where((doc) => itemIdsForSelectedRental.contains(doc.id))
                        .toList();

                    return DropdownButtonFormField<String>(
                      initialValue: selectedItemId,
                      decoration: const InputDecoration(
                        hintText: 'Select an item',
                      ),
                      items: items.map((doc) {
                        final data = doc.data();
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(data['name'] ?? doc.id),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedItemId = value;
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 20),
              Text('Event type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitEvent,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Log Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<_RentalOption>> _loadRentalOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rentals,
  ) async {
    final options = <_RentalOption>[];

    for (final doc in rentals) {
      final data = doc.data();
      final customerId = data['customerId'] as String? ?? '';
      final itemIds = List<String>.from(data['itemIds'] ?? []);

      String customerName = customerId;

      if (customerId.isNotEmpty) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        if (customerDoc.exists) {
          customerName = customerDoc.data()?['name'] ?? customerId;
        }
      }

      options.add(_RentalOption(
        rentalId: doc.id,
        label: '$customerName — ${doc.id.substring(0, 6)}',
        itemIds: itemIds,
      ));
    }

    return options;
  }
}

class _RentalOption {
  final String rentalId;
  final String label;
  final List<String> itemIds;

  _RentalOption({
    required this.rentalId,
    required this.label,
    required this.itemIds,
  });
}
