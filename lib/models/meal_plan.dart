import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlan {
  final String id;
  final String userId;
  final DateTime date;
  final Map<String, List<MealItem>> meals;
  
  MealPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
  });
  
  factory MealPlan.fromMap(Map<String, dynamic> map, String id) {
    final mealsMap = map['meals'] as Map<String, dynamic>? ?? {};
    final meals = <String, List<MealItem>>{};
    
    mealsMap.forEach((mealType, mealItems) {
      meals[mealType] = (mealItems as List<dynamic>)
          .map((item) => MealItem.fromMap(item as Map<String, dynamic>))
          .toList();
    });
    
    return MealPlan(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      meals: meals,
    );
  }
  
  Map<String, dynamic> toMap() {
    final mealsMap = <String, dynamic>{};
    
    meals.forEach((mealType, mealItems) {
      mealsMap[mealType] = mealItems.map((item) => item.toMap()).toList();
    });
    
    return {
      'userId': userId,
      'date': date,
      'meals': mealsMap,
    };
  }
}

class MealItem {
  final String recipeId;
  final String recipeTitle;
  final String recipeImageUrl;
  final int servings;
  
  MealItem({
    required this.recipeId,
    required this.recipeTitle,
    required this.recipeImageUrl,
    required this.servings,
  });
  
  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      recipeId: map['recipeId'] ?? '',
      recipeTitle: map['recipeTitle'] ?? '',
      recipeImageUrl: map['recipeImageUrl'] ?? '',
      servings: map['servings'] ?? 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'recipeImageUrl': recipeImageUrl,
      'servings': servings,
    };
  }
}

