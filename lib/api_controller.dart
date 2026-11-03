import 'dart:convert';

import 'package:http/http.dart' as http;

class UlamRecipe {
  const UlamRecipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.cuisine,
    required this.mealTypes,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.imageUrl,
  });

  factory UlamRecipe.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String || name.isEmpty) {
      throw const FormatException('Recipe data is missing a valid id or name.');
    }

    return UlamRecipe(
      id: id,
      name: name,
      ingredients: _stringList(json['ingredients']),
      instructions: _stringList(json['instructions']),
      cuisine: json['cuisine'] is String
          ? json['cuisine'] as String
          : 'Home-style',
      mealTypes: _stringList(json['mealType']),
      prepTimeMinutes: _integer(json['prepTimeMinutes']),
      cookTimeMinutes: _integer(json['cookTimeMinutes']),
      servings: _integer(json['servings'], fallback: 1),
      imageUrl: json['image'] is String ? json['image'] as String : '',
    );
  }

  final int id;
  final String name;
  final List<String> ingredients;
  final List<String> instructions;
  final String cuisine;
  final List<String> mealTypes;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String imageUrl;

  int get estimatedPrice => 89 + servings * 10;

  static int _integer(Object? value, {int fallback = 0}) =>
      value is int ? value : fallback;

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}

class ApiController {
  ApiController({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _recipesUri = Uri.https('dummyjson.com', '/recipes', {
    'limit': '30',
  });

  final http.Client _client;

  Future<List<UlamRecipe>> getRecipes() async {
    final response = await _client.get(_recipesUri);
    if (response.statusCode != 200) {
      throw Exception(
        'Could not load the ulam catalog (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['recipes'] is! List) {
      throw const FormatException('The ulam catalog response is invalid.');
    }

    final recipes = decoded['recipes'] as List;
    return recipes
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('A recipe in the catalog is invalid.');
          }
          return UlamRecipe.fromJson(item);
        })
        .toList(growable: false);
  }

  void close() => _client.close();
}
