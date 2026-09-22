class ItemModel {
  final String name;
  final String category;
  final String currentStatus;

  ItemModel({
    required this.name,
    required this.category,
    this.currentStatus = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'currentStatus': currentStatus,
      'currentRentalId': null,
      'lastEventTimestamp': null,
    };
  }
}
