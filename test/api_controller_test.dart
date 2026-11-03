import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ma_ano_ulam/api_controller.dart';

void main() {
  test('fetches and maps recipe JSON into catalog items', () async {
    final controller = ApiController(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'dummyjson.com');
        expect(request.url.path, '/recipes');
        expect(request.url.queryParameters['limit'], '30');
        return http.Response(
          jsonEncode({
            'recipes': [
              {
                'id': 42,
                'name': 'Garlic Chicken',
                'ingredients': ['chicken', 'garlic'],
                'instructions': ['Cook until done.'],
                'cuisine': 'Filipino',
                'mealType': ['Dinner'],
                'prepTimeMinutes': 10,
                'cookTimeMinutes': 20,
                'servings': 3,
                'image': 'https://example.com/ulam.webp',
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(controller.close);

    final recipes = await controller.getRecipes();

    expect(recipes, hasLength(1));
    expect(recipes.single.name, 'Garlic Chicken');
    expect(recipes.single.ingredients, ['chicken', 'garlic']);
    expect(recipes.single.cuisine, 'Filipino');
    expect(recipes.single.estimatedPrice, 119);
  });

  test('reports an unsuccessful API response', () async {
    final controller = ApiController(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );
    addTearDown(controller.close);

    expect(
      controller.getRecipes(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('HTTP 503'),
        ),
      ),
    );
  });
}
