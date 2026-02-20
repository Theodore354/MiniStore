import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/data/models/product_model.dart';

void main() {
  test('ProductModel parses full json', () {
    final json = {
      'id': 1,
      'title': 'Test',
      'price': 9.99,
      'description': 'desc',
      'category': 'cat',
      'image': 'url',
      'rating': {'rate': 4.5, 'count': 10},
    };

    final model = ProductModel.fromJson(json);

    expect(model.id, 1);
    expect(model.title, 'Test');
    expect(model.price, 9.99);
    expect(model.description, 'desc');
    expect(model.category, 'cat');
    expect(model.image, 'url');
    expect(model.rating.rate, 4.5);
    expect(model.rating.count, 10);
  });

  test('ProductModel handles null and string values', () {
    final json = {
      'id': '2',
      'title': null,
      'price': '12.5',
      'description': null,
      'category': null,
      'image': null,
      // rating omitted
    };

    final model = ProductModel.fromJson(json);

    expect(model.id, 2);
    expect(model.title, '');
    expect(model.price, 12.5);
    expect(model.description, '');
    expect(model.category, '');
    expect(model.image, '');
    expect(model.rating.rate, 0.0);
    expect(model.rating.count, 0);
  });

  test('ProductModel handles null price and rating types', () {
    final json = {
      'id': 3,
      'title': 't',
      'price': null,
      'description': 'd',
      'category': 'c',
      'image': 'i',
      'rating': {'rate': null, 'count': '5'},
    };

    final model = ProductModel.fromJson(json);

    expect(model.price, 0.0);
    expect(model.rating.rate, 0.0);
    expect(model.rating.count, 5);
  });
}
