import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bitebuddy/models/recipe.dart';

class AIService {
  final String _apiUrl = 'https://us-central1-bitebuddy-app.cloudfunctions.net/generateRecipeRecommendations';

  // Get personalized recipe recommendations based on user preferences and pantry items
  Future<List<Recipe>> getPersonalizedRecipeRecommendations(
      String userId,
      List<String> dietaryPreferences,
      List<String> pantryItems,
      ) async {
    try {
      // First try to get recommendations from the API
      final response = await http.post(
        Uri.parse('$_apiUrl/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'dietaryPreferences': dietaryPreferences,
          'pantryItems': pantryItems,
          'limit': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recommendations = data['recommendations'] as List<dynamic>;

        return recommendations.map((item) {
          final recipeData = item as Map<String, dynamic>;
          return Recipe.fromMap(recipeData, recipeData['id'] as String);
        }).toList();
      }

      // If API fails, fall back to local recommendations
      return _getLocalRecommendations(userId, dietaryPreferences, pantryItems);
    } catch (e) {
      // Fallback to local recommendations
      return _getLocalRecommendations(userId, dietaryPreferences, pantryItems);
    }
  }

  // Generate a recipe based on selected ingredients
  Future<Recipe?> generateRecipeFromIngredients({
    required List<String> ingredients,
    required List<String> dietaryPreferences,
    String? mealType,
    int? maxCookTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': ingredients,
          'dietaryPreferences': dietaryPreferences,
          'mealType': mealType,
          'maxCookTime': maxCookTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recipeData = data['recipe'] as Map<String, dynamic>;
        return Recipe.fromMap(recipeData, 'generated_${DateTime.now().millisecondsSinceEpoch}');
      } else {
        throw Exception('Failed to generate recipe: ${response.statusCode}');
      }
    } catch (e) {
      // If API fails, generate a fallback recipe
      return _generateFallbackRecipe(ingredients, dietaryPreferences, mealType);
    }
  }

  // Local recommendation algorithm when API is unavailable
  Future<List<Recipe>> _getLocalRecommendations(
      String userId,
      List<String> dietaryPreferences,
      List<String> pantryItems,
      ) async {
    try {
      // Create a query to find recipes that match dietary preferences
      Query query = FirebaseFirestore.instance.collection('recipes');

      // If user has dietary preferences, filter by them
      if (dietaryPreferences.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: dietaryPreferences);
      }

      // Get recipes
      final snapshot = await query.limit(20).get();

      // Convert to Recipe objects
      final allRecipes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Recipe.fromMap(data, doc.id);
      }).toList();

      // If we have pantry items, score recipes by how many ingredients they use from pantry
      if (pantryItems.isNotEmpty) {
        // Score each recipe based on pantry match
        final scoredRecipes = allRecipes.map((recipe) {
          int score = 0;

          // Check how many ingredients from the recipe are in the pantry
          for (final ingredient in recipe.ingredients) {
            for (final pantryItem in pantryItems) {
              if (ingredient.toLowerCase().contains(pantryItem.toLowerCase())) {
                score++;
                break;
              }
            }
          }

          return MapEntry(recipe, score);
        }).toList();

        // Sort by score (highest first)
        scoredRecipes.sort((a, b) => b.value.compareTo(a.value));

        // Return top recipes
        return scoredRecipes.take(10).map((entry) => entry.key).toList();
      }

      // If no pantry items, just return the recipes
      return allRecipes.take(10).toList();
    } catch (e) {
      // If all else fails, return featured recipes
      return _getDefaultRecommendations();
    }
  }

  // Fallback to featured recipes
  Future<List<Recipe>> _getDefaultRecommendations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('featured', isEqualTo: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Generate a detailed fallback recipe when API is unavailable
  Recipe? _generateFallbackRecipe(
      List<String> ingredients,
      List<String> dietaryPreferences,
      String? mealType,
      ) {
    // Determine recipe type based on ingredients
    String recipeType = _determineRecipeType(ingredients, mealType);

    // Create a meaningful title
    final title = _generateRecipeTitle(ingredients, recipeType);

    // Create a detailed description
    final description = _generateRecipeDescription(ingredients, dietaryPreferences, recipeType);

    // Generate detailed preparation steps
    final recipeInstructions = _generateDetailedInstructions(ingredients, recipeType);

    // Generate appropriate tags
    final tags = _generateTags(ingredients, dietaryPreferences, mealType, recipeType);

    // Calculate realistic prep and cook times
    final prepTime = _calculatePrepTime(ingredients, recipeType);
    final cookTime = _calculateCookTime(ingredients, recipeType);

    return Recipe(
      id: 'generated_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      imageUrl: '',
      ingredients: _expandIngredients(ingredients),
      instructions: recipeInstructions,
      tags: tags,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: 2,
      authorId: 'ai_system',
      authorName: 'AI Chef',
      createdAt: DateTime.now(),
      featured: false,
      rating: 0.0,
      ratingCount: 0,
    );
  }

  // Helper methods for recipe generation

  String _determineRecipeType(List<String> ingredients, String? mealType) {
    // Check for protein sources
    bool hasChicken = ingredients.any((i) => i.toLowerCase().contains('chicken'));
    bool hasBeef = ingredients.any((i) => i.toLowerCase().contains('beef'));
    bool hasFish = ingredients.any((i) =>
    i.toLowerCase().contains('fish') ||
        i.toLowerCase().contains('salmon') ||
        i.toLowerCase().contains('tuna'));
    bool hasEggs = ingredients.any((i) => i.toLowerCase().contains('egg'));
    bool hasTofu = ingredients.any((i) => i.toLowerCase().contains('tofu'));

    // Check for carbs
    bool hasPasta = ingredients.any((i) =>
    i.toLowerCase().contains('pasta') ||
        i.toLowerCase().contains('spaghetti') ||
        i.toLowerCase().contains('noodle'));
    bool hasRice = ingredients.any((i) => i.toLowerCase().contains('rice'));
    bool hasPotato = ingredients.any((i) => i.toLowerCase().contains('potato'));

    // Check for meal indicators
    bool hasSoup = ingredients.any((i) =>
    i.toLowerCase().contains('broth') ||
        i.toLowerCase().contains('stock'));
    bool hasSalad = ingredients.any((i) =>
    i.toLowerCase().contains('lettuce') ||
        i.toLowerCase().contains('spinach') ||
        i.toLowerCase().contains('arugula'));

    // Determine recipe type based on ingredients
    if (mealType?.toLowerCase() == 'breakfast') {
      if (hasEggs) return 'Breakfast Eggs';
      return 'Breakfast Bowl';
    }

    if (hasSoup) return 'Soup';
    if (hasSalad) return 'Salad';

    if (hasChicken) {
      if (hasPasta) return 'Chicken Pasta';
      if (hasRice) return 'Chicken Rice Bowl';
      return 'Chicken Dish';
    }

    if (hasBeef) {
      if (hasPasta) return 'Beef Pasta';
      if (hasRice) return 'Beef Rice Bowl';
      return 'Beef Dish';
    }

    if (hasFish) {
      if (hasRice) return 'Fish Rice Bowl';
      return 'Fish Dish';
    }

    if (hasTofu) {
      return 'Tofu Stir-Fry';
    }

    if (hasPasta) return 'Pasta Dish';
    if (hasRice) return 'Rice Bowl';
    if (hasPotato) return 'Potato Dish';

    // Default
    return mealType ?? 'Main Dish';
  }

  String _generateRecipeTitle(List<String> ingredients, String recipeType) {
    // Get main ingredients (up to 3)
    final mainIngredients = ingredients.take(3).map((i) => i.split(' ').last).join(', ');

    // Generate title variations
    switch (recipeType) {
      case 'Breakfast Eggs':
        return 'Savory ${mainIngredients.capitalize()} Breakfast Scramble';
      case 'Breakfast Bowl':
        return 'Hearty ${mainIngredients.capitalize()} Breakfast Bowl';
      case 'Soup':
        return 'Homemade ${mainIngredients.capitalize()} Soup';
      case 'Salad':
        return 'Fresh ${mainIngredients.capitalize()} Salad';
      case 'Chicken Pasta':
        return 'Creamy Chicken & ${mainIngredients.capitalize()} Pasta';
      case 'Chicken Rice Bowl':
        return 'Chicken & ${mainIngredients.capitalize()} Rice Bowl';
      case 'Chicken Dish':
        return 'Herb-Roasted Chicken with ${mainIngredients.capitalize()}';
      case 'Beef Pasta':
        return 'Hearty Beef & ${mainIngredients.capitalize()} Pasta';
      case 'Beef Rice Bowl':
        return 'Savory Beef & ${mainIngredients.capitalize()} Rice Bowl';
      case 'Beef Dish':
        return 'Seared Beef with ${mainIngredients.capitalize()}';
      case 'Fish Dish':
        return 'Pan-Seared Fish with ${mainIngredients.capitalize()}';
      case 'Tofu Stir-Fry':
        return 'Tofu & ${mainIngredients.capitalize()} Stir-Fry';
      case 'Pasta Dish':
        return '${mainIngredients.capitalize()} Pasta';
      case 'Rice Bowl':
        return '${mainIngredients.capitalize()} Rice Bowl';
      case 'Potato Dish':
        return 'Roasted Potatoes with ${mainIngredients.capitalize()}';
      default:
        return '${mainIngredients.capitalize()} ${recipeType}';
    }
  }

  String _generateRecipeDescription(List<String> ingredients, List<String> dietaryPreferences, String recipeType) {
    final mainIngredients = ingredients.take(3).map((i) => i.split(' ').last).join(', ');
    final dietaryInfo = dietaryPreferences.isNotEmpty ?
    'This ${dietaryPreferences.join(', ')} recipe ' :
    'This recipe ';

    switch (recipeType) {
      case 'Breakfast Eggs':
        return '${dietaryInfo}combines fluffy eggs with fresh ${mainIngredients} for a nutritious start to your day. Ready in minutes, it\'s perfect for busy mornings or weekend brunches.';
      case 'Soup':
        return '${dietaryInfo}creates a comforting soup featuring ${mainIngredients}. The flavors meld together for a warming meal that\'s both satisfying and nourishing.';
      case 'Salad':
        return '${dietaryInfo}creates a refreshing salad with ${mainIngredients}. Light yet satisfying, it\'s perfect for a healthy lunch or dinner side.';
      case 'Chicken Dish':
        return '${dietaryInfo}transforms simple chicken and ${mainIngredients} into a flavorful meal. The chicken is tender and juicy, complemented perfectly by the other ingredients.';
      case 'Pasta Dish':
        return '${dietaryInfo}combines al dente pasta with ${mainIngredients} for a satisfying meal. The flavors blend beautifully for a dish that feels both comforting and special.';
      default:
        return '${dietaryInfo}transforms ${mainIngredients} into a delicious ${recipeType.toLowerCase()}. Simple to prepare yet full of flavor, this dish is perfect for any occasion.';
    }
  }

  List<String> _expandIngredients(List<String> baseIngredients) {
    // Add quantities and additional ingredients for a complete recipe
    final expandedIngredients = <String>[];

    // Add base ingredients with quantities
    for (final ingredient in baseIngredients) {
      if (ingredient.toLowerCase().contains('chicken')) {
        expandedIngredients.add('2 boneless, skinless chicken breasts');
      } else if (ingredient.toLowerCase().contains('beef')) {
        expandedIngredients.add('1 pound ground beef');
      } else if (ingredient.toLowerCase().contains('fish') ||
          ingredient.toLowerCase().contains('salmon')) {
        expandedIngredients.add('2 salmon fillets (6 oz each)');
      } else if (ingredient.toLowerCase().contains('pasta')) {
        expandedIngredients.add('8 oz pasta of your choice');
      } else if (ingredient.toLowerCase().contains('rice')) {
        expandedIngredients.add('1 cup uncooked rice');
      } else if (ingredient.toLowerCase().contains('potato')) {
        expandedIngredients.add('4 medium potatoes, cubed');
      } else if (ingredient.toLowerCase().contains('onion')) {
        expandedIngredients.add('1 medium onion, diced');
      } else if (ingredient.toLowerCase().contains('garlic')) {
        expandedIngredients.add('3 cloves garlic, minced');
      } else if (ingredient.toLowerCase().contains('tomato')) {
        expandedIngredients.add('2 medium tomatoes, diced');
      } else if (ingredient.toLowerCase().contains('bell pepper')) {
        expandedIngredients.add('1 bell pepper, sliced');
      } else if (ingredient.toLowerCase().contains('carrot')) {
        expandedIngredients.add('2 carrots, sliced');
      } else if (ingredient.toLowerCase().contains('broccoli')) {
        expandedIngredients.add('1 head broccoli, cut into florets');
      } else if (ingredient.toLowerCase().contains('spinach')) {
        expandedIngredients.add('2 cups fresh spinach');
      } else if (ingredient.toLowerCase().contains('cheese')) {
        expandedIngredients.add('1/2 cup shredded cheese');
      } else if (ingredient.toLowerCase().contains('egg')) {
        expandedIngredients.add('4 large eggs');
      } else {
        expandedIngredients.add('1 cup $ingredient');
      }
    }

    // Add common ingredients that most recipes need
    expandedIngredients.add('2 tablespoons olive oil');
    expandedIngredients.add('Salt and pepper to taste');

    // Add additional ingredients based on what's already included
    bool hasProtein = baseIngredients.any((i) =>
    i.toLowerCase().contains('chicken') ||
        i.toLowerCase().contains('beef') ||
        i.toLowerCase().contains('fish') ||
        i.toLowerCase().contains('tofu') ||
        i.toLowerCase().contains('egg'));

    bool hasVegetable = baseIngredients.any((i) =>
    i.toLowerCase().contains('onion') ||
        i.toLowerCase().contains('carrot') ||
        i.toLowerCase().contains('broccoli') ||
        i.toLowerCase().contains('spinach') ||
        i.toLowerCase().contains('tomato') ||
        i.toLowerCase().contains('pepper'));

    bool hasStarch = baseIngredients.any((i) =>
    i.toLowerCase().contains('pasta') ||
        i.toLowerCase().contains('rice') ||
        i.toLowerCase().contains('potato'));

    // Add missing components for a balanced meal
    if (!hasProtein) {
      expandedIngredients.add('1 can chickpeas, drained and rinsed');
    }

    if (!hasVegetable) {
      expandedIngredients.add('1 cup mixed vegetables');
    }

    if (!hasStarch && !baseIngredients.any((i) => i.toLowerCase().contains('bread'))) {
      expandedIngredients.add('2 cups cooked rice or pasta (optional)');
    }

    // Add herbs and spices for flavor
    expandedIngredients.add('1 teaspoon dried herbs (thyme, rosemary, or oregano)');
    expandedIngredients.add('1/2 teaspoon garlic powder');

    return expandedIngredients;
  }

  List<String> _generateDetailedInstructions(List<String> ingredients, String recipeType) {
    // Generate detailed, step-by-step instructions based on recipe type
    final instructions = <String>[];

    // Preparation steps
    instructions.add('Wash and prepare all vegetables. Dice onions, mince garlic, and chop other vegetables into even-sized pieces.');

    bool hasProtein = ingredients.any((i) =>
    i.toLowerCase().contains('chicken') ||
        i.toLowerCase().contains('beef') ||
        i.toLowerCase().contains('fish') ||
        i.toLowerCase().contains('tofu'));

    bool hasPasta = ingredients.any((i) => i.toLowerCase().contains('pasta'));
    bool hasRice = ingredients.any((i) => i.toLowerCase().contains('rice'));

    // Protein preparation
    if (ingredients.any((i) => i.toLowerCase().contains('chicken'))) {
      instructions.add('Season chicken breasts with salt, pepper, and dried herbs on both sides.');
      instructions.add('Heat 1 tablespoon olive oil in a large skillet over medium-high heat.');
      instructions.add('Add chicken breasts and cook for 5-7 minutes on each side until golden brown and internal temperature reaches 165°F (74°C).');
      instructions.add('Remove chicken from the pan and let rest for 5 minutes before slicing.');
    } else if (ingredients.any((i) => i.toLowerCase().contains('beef'))) {
      instructions.add('Heat 1 tablespoon olive oil in a large skillet over medium-high heat.');
      instructions.add('Add ground beef and cook, breaking it apart with a spoon, until browned (about 5-7 minutes).');
      instructions.add('Drain excess fat if necessary.');
    } else if (ingredients.any((i) => i.toLowerCase().contains('fish'))) {
      instructions.add('Pat fish fillets dry with paper towels and season with salt and pepper.');
      instructions.add('Heat 1 tablespoon olive oil in a non-stick skillet over medium-high heat.');
      instructions.add('Place fish skin-side down (if applicable) and cook for 3-4 minutes until crisp.');
      instructions.add('Flip carefully and cook for another 2-3 minutes until fish flakes easily with a fork.');
    } else if (ingredients.any((i) => i.toLowerCase().contains('tofu'))) {
      instructions.add('Press tofu between paper towels to remove excess moisture.');
      instructions.add('Cut tofu into 1-inch cubes and season with salt and pepper.');
      instructions.add('Heat 1 tablespoon olive oil in a non-stick skillet over medium-high heat.');
      instructions.add('Add tofu cubes and cook for 2-3 minutes on each side until golden brown.');
    }

    // Vegetable preparation
    if (ingredients.any((i) => i.toLowerCase().contains('onion') || i.toLowerCase().contains('garlic'))) {
      if (hasProtein) {
        instructions.add('In the same pan, add remaining olive oil.');
      } else {
        instructions.add('Heat olive oil in a large skillet over medium heat.');
      }
      instructions.add('Add onions and sauté for 2-3 minutes until translucent.');
      instructions.add('Add garlic and cook for another 30 seconds until fragrant.');
    }

    if (ingredients.any((i) =>
    i.toLowerCase().contains('carrot') ||
        i.toLowerCase().contains('bell pepper') ||
        i.toLowerCase().contains('broccoli'))) {
      instructions.add('Add harder vegetables (carrots, bell peppers, broccoli) and cook for 4-5 minutes until they begin to soften.');
    }

    if (ingredients.any((i) =>
    i.toLowerCase().contains('tomato') ||
        i.toLowerCase().contains('spinach') ||
        i.toLowerCase().contains('zucchini'))) {
      instructions.add('Add softer vegetables (tomatoes, spinach, zucchini) and cook for 2-3 minutes until just tender.');
    }

    // Starch preparation
    if (hasPasta) {
      instructions.add('Meanwhile, bring a large pot of salted water to a boil.');
      instructions.add('Cook pasta according to package instructions until al dente (usually 8-10 minutes).');
      instructions.add('Drain pasta, reserving 1/2 cup of pasta water.');
    } else if (hasRice) {
      instructions.add('Meanwhile, rinse rice under cold water until water runs clear.');
      instructions.add('In a medium saucepan, combine rice with 2 cups of water and a pinch of salt.');
      instructions.add('Bring to a boil, then reduce heat to low, cover, and simmer for 15-18 minutes until water is absorbed.');
      instructions.add('Remove from heat and let stand, covered, for 5 minutes. Fluff with a fork.');
    } else if (ingredients.any((i) => i.toLowerCase().contains('potato'))) {
      instructions.add('Preheat oven to 425°F (220°C).');
      instructions.add('Toss potato cubes with 1 tablespoon olive oil, salt, pepper, and dried herbs.');
      instructions.add('Spread in a single layer on a baking sheet and roast for 25-30 minutes, turning halfway, until golden and crisp.');
    }

    // Combining everything
    if (recipeType.contains('Soup')) {
      instructions.add('Add 4 cups of broth to the vegetable mixture and bring to a simmer.');
      instructions.add('Reduce heat to medium-low and cook for 15-20 minutes until vegetables are tender.');
      if (hasProtein) {
        instructions.add('Return cooked protein to the pot and heat through for 2-3 minutes.');
      }
      instructions.add('Taste and adjust seasoning with salt and pepper as needed.');
    } else if (recipeType.contains('Salad')) {
      instructions.add('In a large bowl, combine all prepared vegetables.');
      if (hasProtein) {
        instructions.add('Add cooked protein and toss gently to combine.');
      }
      instructions.add('Whisk together 2 tablespoons olive oil, 1 tablespoon vinegar or lemon juice, salt, and pepper to make a dressing.');
      instructions.add('Drizzle dressing over salad and toss to coat evenly.');
    } else if (hasPasta) {
      instructions.add('Add cooked pasta to the vegetable mixture.');
      if (hasProtein) {
        instructions.add('Return cooked protein to the pan and toss everything together.');
      }
      instructions.add('If the mixture seems dry, add a splash of reserved pasta water.');
      instructions.add('Cook for 1-2 minutes until everything is well combined and heated through.');
    } else if (hasRice) {
      if (hasProtein) {
        instructions.add('Return cooked protein to the pan with the vegetables.');
      }
      instructions.add('Add cooked rice to the pan and stir to combine all ingredients.');
      instructions.add('Cook for 2-3 minutes until everything is well combined and heated through.');
    } else {
      if (hasProtein && !instructions.any((i) => i.contains('Return cooked protein'))) {
        instructions.add('Return cooked protein to the pan with the vegetables.');
      }
      instructions.add('Stir all ingredients together and cook for 2-3 minutes until well combined and heated through.');
    }

    // Finishing touches
    if (ingredients.any((i) => i.toLowerCase().contains('cheese'))) {
      instructions.add('Sprinkle cheese over the top and cover until melted, about 1-2 minutes.');
    }

    if (ingredients.any((i) => i.toLowerCase().contains('herb')) ||
        !ingredients.any((i) => i.toLowerCase().contains('spice'))) {
      instructions.add('Garnish with fresh herbs if available.');
    }

    instructions.add('Taste and adjust seasoning with salt and pepper as needed.');
    instructions.add('Serve hot and enjoy!');

    return instructions;
  }

  List<String> _generateTags(List<String> ingredients, List<String> dietaryPreferences, String? mealType, String recipeType) {
    final tags = <String>[];

    // Add meal type
    if (mealType != null) {
      tags.add(mealType);
    } else if (recipeType.contains('Breakfast')) {
      tags.add('Breakfast');
    } else {
      tags.add('Main Dish');
    }

    // Add dietary preferences
    tags.addAll(dietaryPreferences);

    // Add recipe type
    if (recipeType.contains('Soup')) tags.add('Soup');
    if (recipeType.contains('Salad')) tags.add('Salad');
    if (recipeType.contains('Pasta')) tags.add('Pasta');
    if (recipeType.contains('Rice')) tags.add('Rice');

    // Add protein type
    if (ingredients.any((i) => i.toLowerCase().contains('chicken'))) tags.add('Chicken');
    if (ingredients.any((i) => i.toLowerCase().contains('beef'))) tags.add('Beef');
    if (ingredients.any((i) => i.toLowerCase().contains('fish'))) tags.add('Seafood');
    if (ingredients.any((i) => i.toLowerCase().contains('tofu'))) tags.add('Vegetarian');

    // Add cooking style
    bool isQuick = recipeType.contains('Stir-Fry') ||
        ingredients.length < 5 ||
        !ingredients.any((i) =>
        i.toLowerCase().contains('beef') ||
            i.toLowerCase().contains('potato'));

    if (isQuick) tags.add('Quick');
    tags.add('Easy');

    // Add health tag if appropriate
    bool isHealthy = ingredients.any((i) =>
    i.toLowerCase().contains('vegetable') ||
        i.toLowerCase().contains('spinach') ||
        i.toLowerCase().contains('broccoli')) &&
        !ingredients.any((i) =>
        i.toLowerCase().contains('cream') ||
            i.toLowerCase().contains('butter'));

    if (isHealthy) tags.add('Healthy');

    return tags;
  }

  int _calculatePrepTime(List<String> ingredients, String recipeType) {
    // Base prep time
    int prepTime = 10;

    // Add time for more ingredients
    prepTime += (ingredients.length > 5) ? 5 : 0;

    // Add time for specific ingredients that take longer to prep
    if (ingredients.any((i) => i.toLowerCase().contains('potato'))) prepTime += 5;
    if (ingredients.any((i) => i.toLowerCase().contains('carrot'))) prepTime += 3;
    if (ingredients.any((i) => i.toLowerCase().contains('onion'))) prepTime += 2;
    if (ingredients.any((i) => i.toLowerCase().contains('garlic'))) prepTime += 2;

    // Add time for specific recipe types
    if (recipeType.contains('Soup')) prepTime += 5;
    if (recipeType.contains('Salad')) prepTime += 5;

    return prepTime;
  }

  int _calculateCookTime(List<String> ingredients, String recipeType) {
    // Base cook time
    int cookTime = 15;

    // Add time for specific ingredients
    if (ingredients.any((i) => i.toLowerCase().contains('chicken'))) cookTime += 15;
    if (ingredients.any((i) => i.toLowerCase().contains('beef'))) cookTime += 10;
    if (ingredients.any((i) => i.toLowerCase().contains('potato'))) cookTime += 20;
    if (ingredients.any((i) => i.toLowerCase().contains('rice'))) cookTime += 20;
    if (ingredients.any((i) => i.toLowerCase().contains('pasta'))) cookTime += 10;

    // Add time for specific recipe types
    if (recipeType.contains('Soup')) cookTime += 15;
    if (recipeType.contains('Stir-Fry')) cookTime -= 5;
    if (recipeType.contains('Salad')) cookTime -= 10;

    // Ensure minimum cook time
    return cookTime < 5 ? 5 : cookTime;
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

