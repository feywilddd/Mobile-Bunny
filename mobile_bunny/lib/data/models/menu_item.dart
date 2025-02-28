class MenuItem {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final double price;
  final String description;
  final List<String> allergens;

  MenuItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.description,
    required this.allergens,
  });

  factory MenuItem.fromMap(String id, Map<String, dynamic> data) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['image_url'],
      price: (data['price'] as num).toDouble(),
      description: data['description'] ?? '',
      allergens: List<String>.from(data['allergens'] ?? []),
    );
  }
}
