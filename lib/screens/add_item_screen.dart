import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // Controller for text fields

  final nameController = TextEditingController();

  final categoryController = TextEditingController();

  // Item service instance

  final ItemService itemService = ItemService();

  // Loading state

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  // Add item method
  Future<void> addItem() async {
    if (nameController.text.trim().isEmpty ||
        categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final item = ItemModel(
        name: nameController.text.trim(),
        category: categoryController.text.trim(),
      );

      await itemService.addItem(item);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item added')));

      nameController.clear();
      categoryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add item')));
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
      appBar: AppBar(title: const Text('Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : addItem,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
