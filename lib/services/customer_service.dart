import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCustomer(CustomerModel customer) async {
    await _firestore.collection('customers').add(customer.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllCustomers() {
    return _firestore.collection('customers').snapshots();
  }
}
