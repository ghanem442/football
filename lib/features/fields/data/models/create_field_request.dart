class CreateFieldRequest {
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final double? basePrice;
  final double? commissionRate;

  const CreateFieldRequest({
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.basePrice,
    this.commissionRate,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'description': description.trim(),
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        if (basePrice != null) 'basePrice': basePrice,
        if (commissionRate != null) 'commissionRate': commissionRate,
      };
}