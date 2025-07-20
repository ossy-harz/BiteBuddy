import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/models/pantry_item.dart';
import 'package:bitebuddy/models/meal_plan.dart';
import 'package:bitebuddy/widgets/custom_button.dart';

import '../../models/recipe.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _isLoading = false;
  List<ShoppingListItem> _shoppingList = [];
  Map<String, bool> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _generateShoppingList();
  }

  Future<void> _generateShoppingList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      if (userId == null) return;

      // Get pantry items
      final pantrySnapshot = await FirebaseFirestore.instance
          .collection('pantry_items')
          .where('userId', isEqualTo: userId)
          .get();

      final pantryItems = pantrySnapshot.docs.map((doc) {
        final data = doc.data();
        return PantryItem.fromMap(data, doc.id);
      }).toList();

      // Get meal plans for the next 7 days
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final mealPlanDocs = <String>[];
      for (var day = now; day.isBefore(nextWeek); day = day.add(const Duration(days: 1))) {
        mealPlanDocs.add('${userId}_${DateFormat('yyyy-MM-dd').format(day)}');
      }

      final mealPlans = <MealPlan>[];
      for (final docId in mealPlanDocs) {
        final doc = await FirebaseFirestore.instance
            .collection('meal_plans')
            .doc(docId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          mealPlans.add(MealPlan.fromMap(data, doc.id));
        }
      }

      // Get recipes for meal plans
      final recipeIds = <String>{};
      for (final mealPlan in mealPlans) {
        for (final mealItems in mealPlan.meals.values) {
          for (final mealItem in mealItems) {
            recipeIds.add(mealItem.recipeId);
          }
        }
      }

      final recipes = <Recipe>[];
      for (final recipeId in recipeIds) {
        final doc = await FirebaseFirestore.instance
            .collection('recipes')
            .doc(recipeId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          recipes.add(Recipe.fromMap(data, doc.id));
        }
      }

      // Generate shopping list
      final shoppingList = <ShoppingListItem>[];

      // Add low stock pantry items
      for (final item in pantryItems) {
        if (item.isLowStock) {
          shoppingList.add(ShoppingListItem(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            category: item.category,
            source: 'Pantry (Low Stock)',
          ));
        }
      }

      // Add items from recipes that aren't in pantry
      for (final recipe in recipes) {
        for (final ingredient in recipe.ingredients) {
          // Parse ingredient (simple parsing)
          final parts = ingredient.split(' ');
          if (parts.length < 2) continue;

          String quantity = '1';
          String unit = 'pcs';
          String name = ingredient;

          if (parts[0].contains(RegExp(r'[0-9]'))) {
            quantity = parts[0];
            if (parts.length > 1 && _isUnit(parts[1])) {
              unit = parts[1];
              name = parts.sublist(2).join(' ');
            } else {
              name = parts.sublist(1).join(' ');
            }
          }

          // Check if ingredient is in pantry
          final inPantry = pantryItems.any((item) =>
              item.name.toLowerCase().contains(name.toLowerCase()));

          if (!inPantry) {
            // Check if already in shopping list
            final existingIndex = shoppingList.indexWhere((item) =>
            item.name.toLowerCase() == name.toLowerCase());

            if (existingIndex >= 0) {
              // Update quantity
              final existing = shoppingList[existingIndex];
              shoppingList[existingIndex] = ShoppingListItem(
                name: existing.name,
                // Fix: Provide a default value of 1 if parsing returns null
                quantity: existing.quantity + (int.tryParse(quantity) ?? 1),
                unit: existing.unit,
                category: existing.category,
                source: '${existing.source}, ${recipe.title}',
              );
            } else {
              // Add new item
              shoppingList.add(ShoppingListItem(
                name: name,
                // Fix: Provide a default value of 1 if parsing returns null
                quantity: int.tryParse(quantity) ?? 1,
                unit: unit,
                category: _getCategoryForIngredient(name),
                source: recipe.title,
              ));
            }
          }
        }
      }

      // Sort by category
      shoppingList.sort((a, b) => a.category.compareTo(b.category));

      setState(() {
        _shoppingList = shoppingList;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating shopping list: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isUnit(String text) {
    final units = ['g', 'kg', 'ml', 'L', 'tbsp', 'tsp', 'cup', 'cups', 'oz', 'lb', 'pcs', 'bunch'];
    return units.contains(text.toLowerCase());
  }

  String _getCategoryForIngredient(String ingredient) {
    final lowerIngredient = ingredient.toLowerCase();

    if (_containsAny(lowerIngredient, ['apple', 'banana', 'orange', 'berry', 'fruit'])) {
      return 'Fruits';
    } else if (_containsAny(lowerIngredient, ['carrot', 'broccoli', 'lettuce', 'vegetable'])) {
      return 'Vegetables';
    } else if (_containsAny(lowerIngredient, ['milk', 'cheese', 'yogurt', 'cream'])) {
      return 'Dairy';
    } else if (_containsAny(lowerIngredient, ['chicken', 'beef', 'pork', 'fish', 'meat'])) {
      return 'Meat';
    } else if (_containsAny(lowerIngredient, ['rice', 'pasta', 'bread', 'flour'])) {
      return 'Grains';
    } else if (_containsAny(lowerIngredient, ['can', 'canned', 'tin'])) {
      return 'Canned Goods';
    } else if (_containsAny(lowerIngredient, ['salt', 'pepper', 'spice', 'herb'])) {
      return 'Spices';
    } else if (_containsAny(lowerIngredient, ['sugar', 'baking', 'vanilla'])) {
      return 'Baking';
    } else {
      return 'Other';
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  void _toggleItemCheck(int index) {
    final item = _shoppingList[index];
    final key = '${item.name}_${item.unit}';

    setState(() {
      _checkedItems[key] = !(_checkedItems[key] ?? false);
    });
  }

  void _shareShoppingList() {
    final buffer = StringBuffer('Shopping List:\n\n');

    String currentCategory = '';
    for (final item in _shoppingList) {
      if (item.category != currentCategory) {
        buffer.writeln('\n${item.category}:');
        currentCategory = item.category;
      }

      final key = '${item.name}_${item.unit}';
      final isChecked = _checkedItems[key] ?? false;
      buffer.writeln('${isChecked ? '✓' : '☐'} ${item.quantity} ${item.unit} ${item.name}');
    }

    // Share functionality would be implemented here
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shopping list ready to share')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateShoppingList,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareShoppingList,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingList.isEmpty
          ? const Center(child: Text('No items needed for your meal plan'))
          : ListView.builder(
        itemCount: _shoppingList.length,
        itemBuilder: (context, index) {
          final item = _shoppingList[index];
          final key = '${item.name}_${item.unit}';
          final isChecked = _checkedItems[key] ?? false;

          // Add category header
          final bool showCategoryHeader = index == 0 ||
              _shoppingList[index].category != _shoppingList[index - 1].category;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCategoryHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              CheckboxListTile(
                title: Text(
                  item.name,
                  style: TextStyle(
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('${item.quantity} ${item.unit} • ${item.source}'),
                value: isChecked,
                onChanged: (_) => _toggleItemCheck(index),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (index < _shoppingList.length - 1 &&
                  _shoppingList[index].category == _shoppingList[index + 1].category)
                const Divider(height: 1, indent: 70),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          onPressed: _shareShoppingList,
          child: const Text('Share Shopping List'),
        ),
      ),
    );
  }
}

class ShoppingListItem {
  final String name;
  final int quantity;
  final String unit;
  final String category;
  final String source;

  ShoppingListItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.source,
  });
}

