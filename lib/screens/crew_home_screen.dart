import 'package:flutter/material.dart';

class CrewHomeScreen extends StatelessWidget {
  const CrewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Crew Member',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
