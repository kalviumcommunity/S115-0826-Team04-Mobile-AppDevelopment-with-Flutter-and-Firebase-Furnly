class RentalModel {
  final String customerId;
  final List<String> itemIds;
  final DateTime startDate;
  final DateTime expectedReturnDate;
  final double ratePerDay;
  final String billingStatus;

  RentalModel({
    required this.customerId,
    required this.itemIds,
    required this.startDate,
    required this.expectedReturnDate,
    required this.ratePerDay,
    this.billingStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'itemIds': itemIds,
      'startDate': startDate,
      'expectedReturnDate': expectedReturnDate,
      'actualReturnDate': null,
      'billingStatus': billingStatus,
      'ratePerDay': ratePerDay,
      'computedCharge': 0,
    };
  }
}
