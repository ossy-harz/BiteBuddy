import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bitebuddy/models/recipe.dart';
import 'package:bitebuddy/models/meal_plan.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/widgets/recipe_card.dart';

class AddMealScreen extends StatefulWidget {
  final DateTime date;
  final String mealType;

  const AddMealScreen({
    super.key,
    required this.date,
    required this.mealType,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Recipe? _selectedRecipe;
  int _servings = 1;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _addToMealPlan() async {
    if (_selectedRecipe == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser!.uid;
      
      final docId = '${userId}_${DateFormat('yyyy-MM-dd').format(widget.date)}';
      final docRef = FirebaseFirestore.instance.collection('meal_plans').doc(docId);
      
      // Check if document exists
      final doc = await docRef.get();
      
      if (doc.exists) {
        // Update existing meal plan
        final data = doc.data() as Map<String, dynamic>;
        final mealsMap = data['meals'] as Map<String, dynamic>? ?? {};
        final mealItems = List<dynamic>.from(mealsMap[widget.mealType] ?? []);
        
        // Add new meal item
        mealItems.add({
          'recipeId': _selectedRecipe!.id,
          'recipeTitle': _selectedRecipe!.title,
          'recipeImageUrl': _selectedRecipe!.imageUrl,
          'servings': _servings,
        });
        
        mealsMap[widget.mealType] = mealItems;
        
        await docRef.update({'meals': mealsMap});
      } else {
        // Create new meal plan
        final mealItem = MealItem(
          recipeId: _selectedRecipe!.id,
          recipeTitle: _selectedRecipe!.title,
          recipeImageUrl: _selectedRecipe!.imageUrl,
          servings: _servings,
        );
        
        final meals = <String, List<MealItem>>{
          widget.mealType: [mealItem],
        };
        
        final mealPlan = MealPlan(
          id: docId,
          userId: userId,
          date: widget.date,
          meals: meals,
        );
        
        await docRef.set(mealPlan.toMap());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to meal plan')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to meal plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.mealType}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _selectedRecipe != null
                      ? _buildSelectedRecipeView()
                      : _buildRecipeList(),
                ),
              ],
            ),
      bottomNavigationBar: _selectedRecipe != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _addToMealPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add to Meal Plan'),
              ),
            )
          : null,
    );
  }
  
  Widget _buildSelectedRecipeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeCard(
            recipe: _selectedRecipe!,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'Servings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _servings > 1
                    ? () {
                        setState(() {
                          _servings--;
                        });
                      }
                    : null,
              ),
              Text(
                _servings.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _servings++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedRecipe = null;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Choose a Different Recipe'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recipes found'));
        }
        
        final recipes = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Recipe.fromMap(data, doc.id);
        }).toList();
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          recipes.retainWhere((recipe) {
            return recipe.title.toLowerCase().contains(query) ||
                recipe.description.toLowerCase().contains(query) ||
                recipe.tags.any((tag) => tag.toLowerCase().contains(query));
          });
        }
        
        if (recipes.isEmpty) {
          return const Center(child: Text('No recipes match your search'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RecipeCard(
                recipe: recipe,
                isHorizontal: true,
                onTap: () {
                  setState(() {
                    _selectedRecipe = recipe;
                    _servings = recipe.servings;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}

