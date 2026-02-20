/// Domain entity representing a product rating.
class Rating {
  final double rate;
  final int count;

  const Rating({required this.rate, required this.count});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rating &&
          runtimeType == other.runtimeType &&
          rate == other.rate &&
          count == other.count;

  @override
  int get hashCode => rate.hashCode ^ count.hashCode;
}

/// Domain entity representing a product from the Fake Store API.
class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
