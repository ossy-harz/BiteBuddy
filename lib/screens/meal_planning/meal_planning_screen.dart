import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bitebuddy/models/meal_plan.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/screens/meal_planning/add_meal_screen.dart';
import 'package:bitebuddy/screens/recipes/recipe_details_screen.dart';
import 'package:bitebuddy/models/recipe.dart';

class MealPlanningScreen extends StatefulWidget {
  const MealPlanningScreen({super.key});

  @override
  State<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends State<MealPlanningScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;
    
    if (userId == null) {
      return const Center(child: Text('Please sign in to view your meal plans'));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              
              if (pickedDate != null && pickedDate != _selectedDate) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('meal_plans')
                  .doc('${userId}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                MealPlan? mealPlan;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  mealPlan = MealPlan.fromMap(data, snapshot.data!.id);
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mealTypes.length,
                  itemBuilder: (context, index) {
                    final mealType = _mealTypes[index];
                    final mealItems = mealPlan?.meals[mealType] ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  mealType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AddMealScreen(
                                          date: _selectedDate,
                                          mealType: mealType,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (mealItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text('No meals planned'),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: mealItems.length,
                              itemBuilder: (context, index) {
                                final mealItem = mealItems[index];
                                return ListTile(
                                  leading: mealItem.recipeImageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            mealItem.recipeImageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.image),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image),
                                        ),
                                  title: Text(mealItem.recipeTitle),
                                  subtitle: Text('Servings: ${mealItem.servings}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _removeMealItem(userId, mealType, index);
                                    },
                                  ),
                                  onTap: () {
                                    _viewRecipeDetails(mealItem.recipeId);
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeMealItem(String userId, String mealType, int index) async {
    final docId = '${userId}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}';
    final docRef = FirebaseFirestore.instance.collection('meal_plans').doc(docId);
    
    final doc = await docRef.get();
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final mealsMap = data['meals'] as Map<String, dynamic>? ?? {};
    final mealItems = List<dynamic>.from(mealsMap[mealType] ?? []);
    
    if (index >= 0 && index < mealItems.length) {
      mealItems.removeAt(index);
      mealsMap[mealType] = mealItems;
      
      await docRef.update({'meals': mealsMap});
    }
  }
  
  Future<void> _viewRecipeDetails(String recipeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();
      
      if (!doc.exists || !mounted) return;
      
      final data = doc.data() as Map<String, dynamic>;
      final recipe = Recipe.fromMap(data, doc.id);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailsScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipe: $e')),
        );
      }
    }
  }
}

