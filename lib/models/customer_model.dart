class CustomerModel {
  final String name;
  final String contact;

  CustomerModel({required this.name, required this.contact});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact': contact,
      'rentalIds': [],
    };
  }
}
