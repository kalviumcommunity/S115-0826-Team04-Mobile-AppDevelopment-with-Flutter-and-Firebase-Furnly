import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addItem(ItemModel item) async {
    await _firestore.collection('items').add(item.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllItems() {
    return _firestore.collection('items').snapshots();
  }
}
