import 'package:flutter/material.dart';
import '../services/item_service.dart';
import 'add_item_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final itemService = ItemService();
  final searchController = TextEditingController();

  String searchQuery = '';
  String? categoryFilter;

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search items',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: itemService.getAllItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                if (searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final category =
                        (data['category'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery) ||
                        category.contains(searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No matching items.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text(data['category'] ?? ''),
                      trailing: Text(data['currentStatus'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
