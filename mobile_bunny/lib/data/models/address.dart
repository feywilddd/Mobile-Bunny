class Address {
  final String id;
  final String label;
  final String street;
  final String postalCode;
  final String city;
  final String additionalInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.postalCode,
    required this.city,
    this.additionalInfo = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory Address.fromMap(String id, Map<String, dynamic> map) {
    return Address(
      id: id,
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      postalCode: map['postalCode'] ?? '',
      city: map['city'] ?? '',
      additionalInfo: map['additionalInfo'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'street': street,
      'postalCode': postalCode,
      'city': city,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Address copyWith({
    String? label,
    String? street,
    String? postalCode,
    String? city,
    String? additionalInfo,
  }) {
    return Address(
      id: id,
      label: label ?? this.label,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}