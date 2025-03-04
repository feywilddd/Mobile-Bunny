class Profile {
  final String id;
  final String name;
  final List<String> allergens;
  final bool isMainUser;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.name,
    this.allergens = const [],
    this.isMainUser = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromMap(String id, Map<String, dynamic> map) {
    return Profile(
      id: id,
      name: map['name'] ?? '',
      allergens: List<String>.from(map['allergens'] ?? []),
      isMainUser: map['isMainUser'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'allergens': allergens,
      'isMainUser': isMainUser,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Profile copyWith({
    String? name,
    List<String>? allergens,
    bool? isMainUser,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      allergens: allergens ?? this.allergens,
      isMainUser: isMainUser ?? this.isMainUser,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}