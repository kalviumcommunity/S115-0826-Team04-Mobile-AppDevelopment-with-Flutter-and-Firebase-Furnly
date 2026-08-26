import 'package:flutter/material.dart';
import 'log_event_screen.dart';

class CrewHomeScreen extends StatelessWidget {
  const CrewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome, Crew Member',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogEventScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_add),
              label: const Text('Log Event'),
            ),
          ],
        ),
      ),
    );
  }
}
