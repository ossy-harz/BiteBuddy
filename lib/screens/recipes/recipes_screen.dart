import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitebuddy/models/recipe.dart';
import 'package:bitebuddy/screens/recipes/create_recipe_screen.dart';
import 'package:bitebuddy/screens/recipes/recipe_details_screen.dart';
import 'package:bitebuddy/widgets/recipe_card.dart';
import 'package:bitebuddy/widgets/elevated_card.dart';
import 'package:bitebuddy/services/ai_service.dart';
import 'package:provider/provider.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  final int initialTab;

  const RecipesScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _selectedTags = [];
  late TabController _tabController;
  bool _isGeneratingRecipe = false;
  Recipe? _generatedRecipe;

  // For AI recipe generation
  final List<String> _selectedIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  String? _selectedMealType;
  int _maxCookTime = 30;

  final AIService _aiService = AIService();

  final List<String> _categories = [
    'All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack'
  ];

  final List<String> _tags = [
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free',
    'Quick', 'Easy', 'Healthy', 'Comfort Food', 'Spicy',
  ];

  final List<String> _mealTypes = [
    'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ingredientController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Recipes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = 'All';
                            _selectedTags = [];
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Apply filters
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show bottom sheet to select pantry ingredients
  void _showPantryIngredientSelector() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to access your pantry')),
      );
      return;
    }

    // Get pantry items
    final pantrySnapshot = await FirebaseFirestore.instance
        .collection('pantry_items')
        .where('userId', isEqualTo: userId)
        .get();

    if (!mounted) return;

    final pantryItems = pantrySnapshot.docs.map((doc) {
      final data = doc.data();
      return data['name'] as String;
    }).toList();

    if (pantryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your pantry is empty. Add items to your pantry first.')),
      );
      return;
    }

    // Show bottom sheet with pantry items
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Ingredients from Pantry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pantryItems.map((item) {
                      final isSelected = _selectedIngredients.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedIngredients.add(item);
                            } else {
                              _selectedIngredients.remove(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Update selected ingredients in parent
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Add Selected'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Generate recipe with AI
  Future<void> _generateRecipeWithAI() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to generate recipes')),
      );
      return;
    }

    setState(() {
      _isGeneratingRecipe = true;
    });

    try {
      // Get user dietary preferences
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;
      final dietaryPreferences = List<String>.from(userData?['dietaryPreferences'] ?? []);

      // Generate recipe with selected ingredients
      final recipe = await _aiService.generateRecipeFromIngredients(
        ingredients: _selectedIngredients,
        dietaryPreferences: dietaryPreferences,
        mealType: _selectedMealType,
        maxCookTime: _maxCookTime,
      );

      setState(() {
        _generatedRecipe = recipe;
        _isGeneratingRecipe = false;
      });

      if (recipe != null) {
        // Show dialog to save or view recipe
        _showGeneratedRecipeDialog(recipe);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate recipe. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingRecipe = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showGeneratedRecipeDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recipe Generated!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(recipe.description),
              const SizedBox(height: 16),
              Text('Cooking time: ${recipe.cookTime} minutes'),
              Text('Servings: ${recipe.servings}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailsScreen(recipe: recipe),
                ),
              );
            },
            child: const Text('View Recipe'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              // Save the recipe
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.uid;

              if (userId != null) {
                // Create recipe document
                await FirebaseFirestore.instance.collection('recipes').add({
                  'title': recipe.title,
                  'description': recipe.description,
                  'imageUrl': recipe.imageUrl,
                  'ingredients': recipe.ingredients,
                  'instructions': recipe.instructions,
                  'tags': recipe.tags,
                  'prepTime': recipe.prepTime,
                  'cookTime': recipe.cookTime,
                  'servings': recipe.servings,
                  'authorId': userId,
                  'authorName': 'AI Generated',
                  'createdAt': FieldValue.serverTimestamp(),
                  'featured': false,
                  'rating': 0.0,
                  'ratingCount': 0,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recipe saved successfully')),
                  );
                }
              }
            },
            child: const Text('Save Recipe'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recipes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Implement search
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterBottomSheet,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Browse Recipes'),
              Tab(text: 'AI Generator'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBrowseRecipesTab(),
            _buildAIGeneratorTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBrowseRecipesTab() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.zero,
              filled: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('recipes')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No recipes yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first recipe or use the AI generator',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final recipes = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Recipe.fromMap(data, doc.id);
              }).toList();

              if (_searchQuery.isNotEmpty) {
                recipes.retainWhere((recipe) =>
                recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    recipe.description.toLowerCase().contains(_searchQuery.toLowerCase())
                );
              }

              // Apply category filter
              if (_selectedCategory != 'All') {
                recipes.retainWhere((recipe) =>
                    recipe.tags.contains(_selectedCategory)
                );
              }

              // Apply tag filters
              if (_selectedTags.isNotEmpty) {
                recipes.retainWhere((recipe) {
                  for (final tag in _selectedTags) {
                    if (recipe.tags.contains(tag)) {
                      return true;
                    }
                  }
                  return false;
                });
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    isHorizontal: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailsScreen(recipe: recipe),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAIGeneratorTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedCard(
              elevationLevel: 2,
              padding: const EdgeInsets.all(24),
              backgroundColor: theme.colorScheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Recipe Generator',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create custom recipes based on your ingredients and preferences',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ingredients',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      hintText: 'Add an ingredient...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_ingredientController.text.isNotEmpty) {
                      setState(() {
                        _selectedIngredients.add(_ingredientController.text.trim());
                        _ingredientController.clear();
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showPantryIngredientSelector,
              icon: const Icon(Icons.kitchen),
              label: const Text('Select from Pantry'),
            ),
            const SizedBox(height: 16),
            if (_selectedIngredients.isNotEmpty) ...[
              Text(
                'Selected Ingredients:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedIngredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient),
                    onDeleted: () {
                      setState(() {
                        _selectedIngredients.remove(ingredient);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Meal Type (Optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mealTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedMealType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMealType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Maximum Cooking Time',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _maxCookTime.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: '$_maxCookTime minutes',
              onChanged: (value) {
                setState(() {
                  _maxCookTime = value.round();
                });
              },
            ),
            Text(
              'Up to $_maxCookTime minutes',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectedIngredients.isEmpty || _isGeneratingRecipe
                  ? null
                  : _generateRecipeWithAI,
              icon: _isGeneratingRecipe
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingRecipe ? 'Generating Recipe...' : 'Generate Recipe',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedCard(
              elevationLevel: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips for Better Results',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Add at least 3-5 ingredients for better recipes'),
                  const Text('• Include a protein, vegetable, and starch when possible'),
                  const Text('• Set your dietary preferences in your profile'),
                  const Text('• Specify a meal type for more targeted recipes'),
                ],
              ),
            ),
            if (_generatedRecipe != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Your Generated Recipe',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              RecipeCard(
                recipe: _generatedRecipe!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailsScreen(recipe: _generatedRecipe!),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailsScreen(recipe: _generatedRecipe!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final userId = authProvider.currentUser?.uid;

                        if (userId != null) {
                          // Create recipe document
                          await FirebaseFirestore.instance.collection('recipes').add({
                            'title': _generatedRecipe!.title,
                            'description': _generatedRecipe!.description,
                            'imageUrl': _generatedRecipe!.imageUrl,
                            'ingredients': _generatedRecipe!.ingredients,
                            'instructions': _generatedRecipe!.instructions,
                            'tags': _generatedRecipe!.tags,
                            'prepTime': _generatedRecipe!.prepTime,
                            'cookTime': _generatedRecipe!.cookTime,
                            'servings': _generatedRecipe!.servings,
                            'authorId': userId,
                            'authorName': 'AI Generated',
                            'createdAt': FieldValue.serverTimestamp(),
                            'featured': false,
                            'rating': 0.0,
                            'ratingCount': 0,
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recipe saved successfully')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Recipe'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

