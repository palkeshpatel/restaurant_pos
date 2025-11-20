class Business {
  final int id;
  final String name;
  final String llcName;
  final String address;
  final String? logoUrl;
  final String timezone;
  final String autoGratuityPercent;
  final int autoGratuityMinGuests;
  final String ccFeePercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.llcName,
    required this.address,
    this.logoUrl,
    required this.timezone,
    required this.autoGratuityPercent,
    required this.autoGratuityMinGuests,
    required this.ccFeePercent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      llcName: json['llc_name'] ?? '',
      address: json['address'] ?? '',
      logoUrl: json['logo_url'],
      timezone: json['timezone'] ?? 'UTC',
      autoGratuityPercent: json['auto_gratuity_percent'] ?? '0.00',
      autoGratuityMinGuests: json['auto_gratuity_min_guests'] ?? 0,
      ccFeePercent: json['cc_fee_percent'] ?? '0.00',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
