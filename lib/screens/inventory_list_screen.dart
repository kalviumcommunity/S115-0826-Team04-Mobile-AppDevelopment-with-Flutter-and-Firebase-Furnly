import 'package:flutter/material.dart';
import '../services/item_service.dart';
import 'add_item_screen.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemService = ItemService();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: itemService.getAllItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No items yet. Tap + to add one.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['category'] ?? ''),
                trailing: Text(data['currentStatus'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
