import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bitebuddy/models/recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiAIService {
  // In a real app, this would be stored securely and not hardcoded
  final String _apiKey = 'AIzaSyAHVJMRdtoHgw4fXM5Ad8P2zRzItHiTwcE';
  final String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Generate a recipe based on ingredients and preferences
  Future<Recipe?> generateRecipe({
    required List<String> ingredients,
    required List<String> dietaryPreferences,
    String? mealType,
    int? maxCookTime,
  }) async {
    try {
      final prompt = _buildRecipePrompt(
        ingredients: ingredients,
        dietaryPreferences: dietaryPreferences,
        mealType: mealType,
        maxCookTime: maxCookTime,
      );

      final response = await _generateContent(prompt);

      if (response != null) {
        return _parseRecipeFromResponse(response);
      }

      return null;
    } catch (e) {
      print('Error generating recipe: $e');
      return null;
    }
  }

  // Generate meal plan for a week based on preferences
  Future<Map<String, List<Recipe>>?> generateMealPlan({
    required List<String> dietaryPreferences,
    required int servingsPerMeal,
    required List<String> availableIngredients,
    bool includeShopping = true,
  }) async {
    try {
      final prompt = _buildMealPlanPrompt(
        dietaryPreferences: dietaryPreferences,
        servingsPerMeal: servingsPerMeal,
        availableIngredients: availableIngredients,
        includeShopping: includeShopping,
      );

      final response = await _generateContent(prompt);

      if (response != null) {
        return _parseMealPlanFromResponse(response);
      }

      return null;
    } catch (e) {
      print('Error generating meal plan: $e');
      return null;
    }
  }

  // Get cooking tips and substitutions
  Future<String?> getCookingTips({
    required String recipe,
    List<String>? availableIngredients,
    List<String>? dietaryPreferences,
  }) async {
    try {
      final prompt = _buildCookingTipsPrompt(
        recipe: recipe,
        availableIngredients: availableIngredients,
        dietaryPreferences: dietaryPreferences,
      );

      final response = await _generateContent(prompt);

      if (response != null) {
        return response;
      }

      return null;
    } catch (e) {
      print('Error getting cooking tips: $e');
      return null;
    }
  }

  // Analyze a recipe for nutrition information
  Future<Map<String, dynamic>?> analyzeRecipeNutrition({
    required Recipe recipe,
  }) async {
    try {
      final prompt = _buildNutritionAnalysisPrompt(recipe: recipe);

      final response = await _generateContent(prompt);

      if (response != null) {
        return _parseNutritionFromResponse(response);
      }

      return null;
    } catch (e) {
      print('Error analyzing recipe nutrition: $e');
      return null;
    }
  }

  // Private methods

  Future<String?> _generateContent(String prompt) async {
    try {
      final url = Uri.parse('$_apiUrl?key=$_apiKey');

      final payload = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text;
      } else {
        print('Error from Gemini API: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      return null;
    }
  }

  String _buildRecipePrompt({
    required List<String> ingredients,
    required List<String> dietaryPreferences,
    String? mealType,
    int? maxCookTime,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Generate a detailed recipe using the following ingredients:');
    buffer.writeln(ingredients.join(', '));

    buffer.writeln('\nDietary preferences:');
    buffer.writeln(dietaryPreferences.join(', '));

    if (mealType != null) {
      buffer.writeln('\nMeal type: $mealType');
    }

    if (maxCookTime != null) {
      buffer.writeln('\nMaximum cooking time: $maxCookTime minutes');
    }

    buffer.writeln('\nPlease format the response as follows:');
    buffer.writeln('TITLE: [Recipe Title]');
    buffer.writeln('DESCRIPTION: [Brief description]');
    buffer.writeln('PREP_TIME: [Prep time in minutes]');
    buffer.writeln('COOK_TIME: [Cook time in minutes]');
    buffer.writeln('SERVINGS: [Number of servings]');
    buffer.writeln('INGREDIENTS:');
    buffer.writeln('- [Ingredient 1]');
    buffer.writeln('- [Ingredient 2]');
    buffer.writeln('...');
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('1. [Step 1]');
    buffer.writeln('2. [Step 2]');
    buffer.writeln('...');
    buffer.writeln('TAGS:');
    buffer.writeln('[tag1], [tag2], ...');

    return buffer.toString();
  }

  String _buildMealPlanPrompt({
    required List<String> dietaryPreferences,
    required int servingsPerMeal,
    required List<String> availableIngredients,
    bool includeShopping = true,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Generate a 7-day meal plan with breakfast, lunch, and dinner for each day.');
    buffer.writeln('\nDietary preferences:');
    buffer.writeln(dietaryPreferences.join(', '));

    buffer.writeln('\nServings per meal: $servingsPerMeal');

    buffer.writeln('\nAvailable ingredients:');
    buffer.writeln(availableIngredients.join(', '));

    if (includeShopping) {
      buffer.writeln('\nPlease include a shopping list of additional ingredients needed.');
    }

    buffer.writeln('\nPlease format the response as follows:');
    buffer.writeln('DAY 1:');
    buffer.writeln('BREAKFAST: [Recipe Title] - [Brief description]');
    buffer.writeln('LUNCH: [Recipe Title] - [Brief description]');
    buffer.writeln('DINNER: [Recipe Title] - [Brief description]');
    buffer.writeln('...');

    if (includeShopping) {
      buffer.writeln('SHOPPING LIST:');
      buffer.writeln('- [Item 1]');
      buffer.writeln('- [Item 2]');
      buffer.writeln('...');
    }

    return buffer.toString();
  }

  String _buildCookingTipsPrompt({
    required String recipe,
    List<String>? availableIngredients,
    List<String>? dietaryPreferences,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Provide cooking tips, techniques, and possible ingredient substitutions for the following recipe:');
    buffer.writeln(recipe);

    if (availableIngredients != null && availableIngredients.isNotEmpty) {
      buffer.writeln('\nAvailable ingredients:');
      buffer.writeln(availableIngredients.join(', '));
    }

    if (dietaryPreferences != null && dietaryPreferences.isNotEmpty) {
      buffer.writeln('\nDietary preferences:');
      buffer.writeln(dietaryPreferences.join(', '));
    }

    buffer.writeln('\nPlease include:');
    buffer.writeln('1. Cooking techniques to improve the dish');
    buffer.writeln('2. Possible ingredient substitutions');
    buffer.writeln('3. Tips for meal prep or storage');
    buffer.writeln('4. Flavor enhancement suggestions');

    return buffer.toString();
  }

  String _buildNutritionAnalysisPrompt({
    required Recipe recipe,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Analyze the nutritional content of the following recipe:');
    buffer.writeln('Title: ${recipe.title}');
    buffer.writeln('Ingredients:');
    for (final ingredient in recipe.ingredients) {
      buffer.writeln('- $ingredient');
    }
    buffer.writeln('Servings: ${recipe.servings}');

    buffer.writeln('\nPlease provide a detailed nutritional analysis including:');
    buffer.writeln('1. Calories per serving');
    buffer.writeln('2. Macronutrients (protein, carbs, fat) per serving');
    buffer.writeln('3. Key vitamins and minerals');
    buffer.writeln('4. Dietary considerations (gluten-free, dairy-free, etc.)');

    buffer.writeln('\nPlease format the response as follows:');
    buffer.writeln('CALORIES: [calories per serving]');
    buffer.writeln('PROTEIN: [protein in grams]');
    buffer.writeln('CARBS: [carbs in grams]');
    buffer.writeln('FAT: [fat in grams]');
    buffer.writeln('FIBER: [fiber in grams]');
    buffer.writeln('VITAMINS: [key vitamins]');
    buffer.writeln('MINERALS: [key minerals]');
    buffer.writeln('CONSIDERATIONS: [dietary considerations]');

    return buffer.toString();
  }

  Recipe? _parseRecipeFromResponse(String response) {
    try {
      final lines = response.split('\n');

      String title = '';
      String description = '';
      int prepTime = 0;
      int cookTime = 0;
      int servings = 1;
      List<String> ingredients = [];
      List<String> instructions = [];
      List<String> tags = [];

      bool parsingIngredients = false;
      bool parsingInstructions = false;
      bool parsingTags = false;

      for (final line in lines) {
        if (line.startsWith('TITLE:')) {
          title = line.substring(6).trim();
        } else if (line.startsWith('DESCRIPTION:')) {
          description = line.substring(12).trim();
        } else if (line.startsWith('PREP_TIME:')) {
          prepTime = int.tryParse(line.substring(10).trim().split(' ')[0]) ?? 0;
        } else if (line.startsWith('COOK_TIME:')) {
          cookTime = int.tryParse(line.substring(10).trim().split(' ')[0]) ?? 0;
        } else if (line.startsWith('SERVINGS:')) {
          servings = int.tryParse(line.substring(9).trim()) ?? 1;
        } else if (line.startsWith('INGREDIENTS:')) {
          parsingIngredients = true;
          parsingInstructions = false;
          parsingTags = false;
        } else if (line.startsWith('INSTRUCTIONS:')) {
          parsingIngredients = false;
          parsingInstructions = true;
          parsingTags = false;
        } else if (line.startsWith('TAGS:')) {
          parsingIngredients = false;
          parsingInstructions = false;
          parsingTags = true;
        } else if (line.trim().isNotEmpty) {
          if (parsingIngredients) {
            if (line.trim().startsWith('-')) {
              ingredients.add(line.trim().substring(1).trim());
            }
          } else if (parsingInstructions) {
            if (RegExp(r'^\d+\.').hasMatch(line.trim())) {
              instructions.add(line.trim().replaceFirst(RegExp(r'^\d+\.\s*'), ''));
            }
          } else if (parsingTags) {
            tags = line.split(',').map((tag) => tag.trim()).toList();
          }
        }
      }

      // Generate a unique ID for the recipe
      final id = 'generated_${DateTime.now().millisecondsSinceEpoch}';

      return Recipe(
        id: id,
        title: title,
        description: description,
        imageUrl: '', // No image for generated recipes
        ingredients: ingredients,
        instructions: instructions,
        tags: tags,
        prepTime: prepTime,
        cookTime: cookTime,
        servings: servings,
        authorId: 'ai_gemini',
        authorName: 'Gemini AI',
        createdAt: DateTime.now(),
        featured: false,
        rating: 0.0,
        ratingCount: 0,
      );
    } catch (e) {
      print('Error parsing recipe from response: $e');
      return null;
    }
  }

  Map<String, List<Recipe>>? _parseMealPlanFromResponse(String response) {
    try {
      final mealPlan = <String, List<Recipe>>{};
      final lines = response.split('\n');

      String currentDay = '';

      for (final line in lines) {
        if (line.startsWith('DAY ')) {
          currentDay = line.trim();
          mealPlan[currentDay] = [];
        } else if (line.startsWith('BREAKFAST:') || line.startsWith('LUNCH:') || line.startsWith('DINNER:')) {
          final mealType = line.split(':')[0].trim();
          final mealInfo = line.substring(mealType.length + 1).trim();

          final parts = mealInfo.split(' - ');
          final title = parts[0].trim();
          final description = parts.length > 1 ? parts[1].trim() : '';

          final id = 'generated_${DateTime.now().millisecondsSinceEpoch}_${mealType.toLowerCase()}_${currentDay.toLowerCase()}';

          final recipe = Recipe(
            id: id,
            title: title,
            description: description,
            imageUrl: '',
            ingredients: [],
            instructions: [],
            tags: [mealType],
            prepTime: 0,
            cookTime: 0,
            servings: 0,
            authorId: 'ai_gemini',
            authorName: 'Gemini AI',
            createdAt: DateTime.now(),
            featured: false,
            rating: 0.0,
            ratingCount: 0,
          );

          mealPlan[currentDay]?.add(recipe);
        }
      }

      return mealPlan;
    } catch (e) {
      print('Error parsing meal plan from response: $e');
      return null;
    }
  }

  Map<String, dynamic>? _parseNutritionFromResponse(String response) {
    try {
      final nutrition = <String, dynamic>{};
      final lines = response.split('\n');

      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          final key = parts[0].trim();
          final value = parts[1].trim();

          nutrition[key] = value;
        }
      }

      return nutrition;
    } catch (e) {
      print('Error parsing nutrition from response: $e');
      return null;
    }
  }

  // Save a generated recipe to Firestore
  Future<void> saveGeneratedRecipe(Recipe recipe, String userId) async {
    try {
      // Update the recipe with the user's ID
      final updatedRecipe = Recipe(
        id: recipe.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: recipe.imageUrl,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        tags: recipe.tags,
        prepTime: recipe.prepTime,
        cookTime: recipe.cookTime,
        servings: recipe.servings,
        authorId: userId, // Set the user as the author
        authorName: 'Generated by AI', // Indicate it was AI-generated
        createdAt: DateTime.now(),
        featured: false,
        rating: 0.0,
        ratingCount: 0,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('recipes')
          .add(updatedRecipe.toMap());
    } catch (e) {
      print('Error saving generated recipe: $e');
    }
  }
}

