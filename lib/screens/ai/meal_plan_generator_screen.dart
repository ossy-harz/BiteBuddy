import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/services/gemini_ai_service.dart';
import 'package:bitebuddy/models/recipe.dart';
import 'package:bitebuddy/screens/recipes/recipe_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanGeneratorScreen extends StatefulWidget {
  const MealPlanGeneratorScreen({super.key});

  @override
  State<MealPlanGeneratorScreen> createState() => _MealPlanGeneratorScreenState();
}

class _MealPlanGeneratorScreenState extends State<MealPlanGeneratorScreen> {
  final GeminiAIService _geminiService = GeminiAIService();

  List<String> _selectedDietaryPreferences = [];
  int _servingsPerMeal = 2;
  bool _includeShopping = true;
  bool _isGenerating = false;
  Map<String, List<Recipe>>? _generatedMealPlan;
  List<String>? _shoppingList;
  String? _errorMessage;

  final List<String> _dietaryOptions = [
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free',
    'Keto', 'Paleo', 'Low-Carb', 'Low-Fat', 'High-Protein'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          final dietaryPreferences = List<String>.from(userData?['dietaryPreferences'] ?? []);

          if (mounted) {
            setState(() {
              _selectedDietaryPreferences = dietaryPreferences;
            });
          }
        }
      } catch (e) {
        print('Error loading user preferences: $e');
      }
    }
  }

  Future<void> _generateMealPlan() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedMealPlan = null;
      _shoppingList = null;
    });

    try {
      // Get pantry items for the user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      List<String> availableIngredients = [];

      if (userId != null) {
        final pantrySnapshot = await FirebaseFirestore.instance
            .collection('pantry_items')
            .where('userId', isEqualTo: userId)
            .get();

        availableIngredients = pantrySnapshot.docs.map((doc) {
          final data = doc.data();
          return data['name'] as String;
        }).toList();
      }

      final mealPlanResponse = await _geminiService.generateMealPlan(
        dietaryPreferences: _selectedDietaryPreferences,
        servingsPerMeal: _servingsPerMeal,
        availableIngredients: availableIngredients,
        includeShopping: _includeShopping,
      );

      if (mounted) {
        setState(() {
          _generatedMealPlan = mealPlanResponse;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error generating meal plan: $e';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Planner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 40,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini AI Meal Planner',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate a personalized 7-day meal plan based on your preferences',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dietary preferences
            Text(
              'Dietary Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietaryOptions.map((preference) {
                final isSelected = _selectedDietaryPreferences.contains(preference);
                return FilterChip(
                  label: Text(preference),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDietaryPreferences.add(preference);
                      } else {
                        _selectedDietaryPreferences.remove(preference);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Servings per meal
            Text(
              'Servings Per Meal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _servingsPerMeal.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: '$_servingsPerMeal servings',
                    onChanged: (value) {
                      setState(() {
                        _servingsPerMeal = value.round();
                      });
                    },
                  ),
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_servingsPerMeal ${_servingsPerMeal == 1 ? 'person' : 'people'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Include shopping list
            SwitchListTile(
              title: const Text('Include Shopping List'),
              subtitle: const Text('Generate a shopping list for the meal plan'),
              value: _includeShopping,
              onChanged: (value) {
                setState(() {
                  _includeShopping = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateMealPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Generate Meal Plan'),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],

            if (_generatedMealPlan != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                'Your 7-Day Meal Plan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Meal plan cards
              ..._generatedMealPlan!.entries.map((entry) {
                final day = entry.key;
                final meals = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final meal in meals) ...[
                              Text(
                                meal.tags.first, // Meal type (Breakfast, Lunch, Dinner)
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(meal.title),
                                subtitle: Text(meal.description),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailsScreen(recipe: meal),
                                    ),
                                  );
                                },
                              ),
                              if (meal != meals.last) const Divider(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              if (_shoppingList != null && _shoppingList!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Shopping List',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in _shoppingList!) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item),
                              ),
                            ],
                          ),
                          if (item != _shoppingList!.last)
                            const Divider(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

