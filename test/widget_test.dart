import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/presentation/widgets/product_card.dart';

void main() {
  const testProduct = ProductModel(
    id: 1,
    title: 'Super Cool Test Widget Product',
    price: 99.99,
    description: 'A product for testing the widget',
    category: 'electronics',
    image: 'https://fakestoreapi.com/img/test.png',
    rating: RatingModel(rate: 4.5, count: 250),
  );

  group('ProductCard Widget', () {
    testWidgets('displays product title and price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ProductCard(
                product: testProduct,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Allow widget tree to build (pump once, don't pumpAndSettle due to network image animations)
      await tester.pump();

      // Verify title is displayed
      expect(find.text('Super Cool Test Widget Product'), findsOneWidget);

      // Verify price is displayed
      expect(find.text('\$99.99'), findsOneWidget);

      // Verify rating is displayed
      expect(find.text('4.5'), findsOneWidget);

      // Verify star icon exists
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ProductCard(
                product: testProduct,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap the card
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('handles different price formats correctly', (tester) async {
      const cheapProduct = ProductModel(
        id: 2,
        title: 'Cheap Product',
        price: 7.50,
        description: 'A cheap product',
        category: 'clothing',
        image: 'https://example.com/img.jpg',
        rating: RatingModel(rate: 2.1, count: 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ProductCard(
                product: cheapProduct,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('\$7.50'), findsOneWidget);
      expect(find.text('2.1'), findsOneWidget);
    });
  });
}
