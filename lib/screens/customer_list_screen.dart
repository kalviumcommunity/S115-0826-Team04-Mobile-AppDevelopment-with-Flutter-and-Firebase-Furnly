import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerService = CustomerService();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, customerService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: customerService.getAllCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No customers yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['contact'] ?? ''),
                trailing: Text(
                  docs[index].id.substring(0, 6),
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(
    BuildContext context,
    CustomerService customerService,
  ) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                await customerService.addCustomer(
                  CustomerModel(
                    name: nameController.text.trim(),
                    contact: contactController.text.trim(),
                  ),
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
