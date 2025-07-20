class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final bool featured;
  final double rating;
  final int ratingCount;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.featured = false,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      prepTime: map['prepTime'] ?? 0,
      cookTime: map['cookTime'] ?? 0,
      servings: map['servings'] ?? 1,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      featured: map['featured'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'instructions': instructions,
      'tags': tags,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'featured': featured,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }
}

