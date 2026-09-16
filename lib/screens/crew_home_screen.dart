import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'log_event_screen.dart';
import 'login_screen.dart';

class CrewHomeScreen extends StatelessWidget {
  const CrewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogEventScreen()),
                );
              },
              child: const Text('Log Delivery / Pickup'),
            ),
          ],
        ),
      ),
    );
  }
}
