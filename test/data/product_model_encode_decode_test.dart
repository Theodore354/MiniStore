import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/data/models/product_model.dart';

void main() {
  test('ProductModel encode/decode list roundtrip', () {
    final products = [
      ProductModel(
        id: 1,
        title: 'A',
        price: 1.0,
        description: 'd',
        category: 'c',
        image: '',
        rating: const RatingModel(rate: 4.0, count: 2),
      ),
      ProductModel(
        id: 2,
        title: 'B',
        price: 2.5,
        description: 'd2',
        category: 'c2',
        image: '',
        rating: const RatingModel(rate: 3.5, count: 5),
      ),
    ];

    final encoded = ProductModel.encodeList(products);
    final decoded = ProductModel.decodeList(encoded);

    expect(decoded.length, products.length);
    expect(decoded[0].id, products[0].id);
    expect(decoded[1].title, products[1].title);
    expect(decoded[1].price, products[1].price);
  });
}
