import 'package:flutter/material.dart';
import '../widgets/conflict_alert.dart';

class AlertDemoScreen extends StatelessWidget {
  const AlertDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ConflictAlert(
          title: 'Conflict Detected',
          message:
              'This item is already assigned to another rental.',
          onReview: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Review action clicked',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
