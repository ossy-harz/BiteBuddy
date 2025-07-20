import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/models/recipe.dart';
import 'package:bitebuddy/widgets/recipe_card.dart';
import 'package:bitebuddy/widgets/duotone_card.dart';
import 'package:bitebuddy/services/ai_service.dart';
import 'package:bitebuddy/screens/recipes/recipe_details_screen.dart';
import 'package:bitebuddy/screens/pantry/shopping_list_screen.dart';
import 'package:bitebuddy/screens/recipes/recipes_screen.dart';
import 'package:bitebuddy/screens/meal_planning/meal_planning_screen.dart';
import 'package:bitebuddy/screens/pantry/pantry_screen.dart';
import 'package:bitebuddy/theme/duotone_theme.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final AIService _aiService = AIService();
  List<Recipe> _recommendations = [];
  List<Recipe> _featuredRecipes = [];
  bool _isLoadingRecommendations = false;
  bool _isLoadingFeatured = false;
  bool _isLoadingStats = false;
  int _plannedMealsCount = 0;
  int _expiringItemsCount = 0;
  int _pantryItemsCount = 0;
  int _savedRecipesCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadFeaturedRecipes();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Get planned meals count for the next 7 days
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      int plannedMealsCount = 0;
      for (var day = now; day.isBefore(nextWeek); day = day.add(const Duration(days: 1))) {
        final docId = '${userId}_${DateFormat('yyyy-MM-dd').format(day)}';
        final doc = await FirebaseFirestore.instance
            .collection('meal_plans')
            .doc(docId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final mealsMap = data['meals'] as Map<String, dynamic>? ?? {};

          for (final mealItems in mealsMap.values) {
            plannedMealsCount += (mealItems as List).length;
          }
        }
      }

      // Get expiring items count (items expiring in the next 3 days)
      final threeDaysLater = now.add(const Duration(days: 3));
      final pantrySnapshot = await FirebaseFirestore.instance
          .collection('pantry_items')
          .where('userId', isEqualTo: userId)
          .get();

      int expiringItemsCount = 0;
      for (final doc in pantrySnapshot.docs) {
        final data = doc.data();
        if (data['expiryDate'] != null) {
          final expiryDate = (data['expiryDate'] as Timestamp).toDate();
          if (expiryDate.isBefore(threeDaysLater) && expiryDate.isAfter(now)) {
            expiringItemsCount++;
          }
        }
      }

      // Get total pantry items count
      final pantryItemsCount = pantrySnapshot.docs.length;

      // Get saved recipes count
      final savedRecipesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      final savedRecipesCount = savedRecipesSnapshot.docs.length;

      if (mounted) {
        setState(() {
          _plannedMealsCount = plannedMealsCount;
          _expiringItemsCount = expiringItemsCount;
          _pantryItemsCount = pantryItemsCount;
          _savedRecipesCount = savedRecipesCount;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      // Get user dietary preferences
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;
      final dietaryPreferences = List<String>.from(userData?['dietaryPreferences'] ?? []);

      // Get pantry items
      final pantrySnapshot = await FirebaseFirestore.instance
          .collection('pantry_items')
          .where('userId', isEqualTo: userId)
          .get();

      final pantryItems = pantrySnapshot.docs.map((doc) {
        final data = doc.data();
        return data['name'] as String;
      }).toList();

      // Get recommendations
      final recommendations = await _aiService.getPersonalizedRecipeRecommendations(
        userId,
        dietaryPreferences,
        pantryItems,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadFeaturedRecipes() async {
    setState(() {
      _isLoadingFeatured = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('featured', isEqualTo: true)
          .limit(5)
          .get();

      final recipes = snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe.fromMap(data, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _featuredRecipes = recipes;
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFeatured = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get current time to personalize greeting
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadRecommendations(),
            _loadFeaturedRecipes(),
            _loadStats(),
          ]);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                ),
                titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'BiteBuddy',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ShoppingListScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () {
                    // Navigate to search
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecipesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text(
                            '$greeting!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return Text(
                            '$greeting!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        final name = userData?['name'] as String? ?? '';
                        final firstName = name.split(' ').first;

                        return Text(
                          '$greeting, ${firstName.isNotEmpty ? firstName : "there"}!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to cook today?',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                          context,
                          icon: Icons.restaurant_menu,
                          label: 'Recipes',
                          color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RecipesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.calendar_today,
                          label: 'Meal Plan',
                          color: DuotoneTheme.accent1,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MealPlanningScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.kitchen,
                          label: 'Pantry',
                          color: DuotoneTheme.accent2,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PantryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.shopping_cart,
                          label: 'Shopping',
                          color: DuotoneTheme.accent3,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ShoppingListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Kitchen Stats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _isLoadingStats
                            ? const ShimmerStatsCard()
                            : _buildStatsCard(
                          context,
                          title: 'Planned Meals',
                          value: _plannedMealsCount.toString(),
                          icon: Icons.calendar_today_rounded,
                          color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MealPlanningScreen(),
                              ),
                            );
                          },
                        ),
                        _isLoadingStats
                            ? const ShimmerStatsCard()
                            : _buildStatsCard(
                          context,
                          title: 'Expiring Items',
                          value: _expiringItemsCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: DuotoneTheme.warning,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PantryScreen(),
                              ),
                            );
                          },
                        ),
                        _isLoadingStats
                            ? const ShimmerStatsCard()
                            : _buildStatsCard(
                          context,
                          title: 'Pantry Items',
                          value: _pantryItemsCount.toString(),
                          icon: Icons.kitchen_rounded,
                          color: DuotoneTheme.accent2,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PantryScreen(),
                              ),
                            );
                          },
                        ),
                        _isLoadingStats
                            ? const ShimmerStatsCard()
                            : _buildStatsCard(
                          context,
                          title: 'Saved Recipes',
                          value: _savedRecipesCount.toString(),
                          icon: Icons.favorite_rounded,
                          color: DuotoneTheme.accent5,
                          onTap: () {
                            // Navigate to saved recipes
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Featured Recipes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Recipes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RecipesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isLoadingFeatured
                        ? SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            margin: const EdgeInsets.only(right: 16),
                            child: const ShimmerFeaturedCard(),
                          );
                        },
                      ),
                    )
                        : _featuredRecipes.isEmpty
                        ? DuotoneCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 48,
                                color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No featured recipes yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featuredRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _featuredRecipes[index];
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildFeaturedCard(recipe),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recommended Recipes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recommended For You',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RecipesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isLoadingRecommendations
                        ? SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 16),
                            child: const ShimmerRecipeCard(),
                          );
                        },
                      ),
                    )
                        : _recommendations.isEmpty
                        ? DuotoneCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 48,
                                color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recommendations yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add more items to your pantry',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRecommendations,
                                child: const Text('Refresh Recommendations'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        : SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final recipe = _recommendations[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 16),
                            child: RecipeCard(
                              recipe: recipe,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailsScreen(recipe: recipe),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Recipes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Recipes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RecipesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Recipes List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ShimmerRecipeCard(isHorizontal: true),
                        );
                      },
                      childCount: 3,
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No recipes available'),
                      ),
                    ),
                  );
                }

                final recipes = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Recipe.fromMap(data, doc.id);
                }).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final recipe = recipes[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: RecipeCard(
                          recipe: recipe,
                          isHorizontal: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailsScreen(recipe: recipe),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: recipes.length,
                  ),
                );
              },
            ),

            // Add some space at the bottom
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return DuotoneCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Recipe recipe) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(recipe: recipe),
          ),
        );
      },
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              child: recipe.imageUrl.isNotEmpty
                  ? ColorFiltered(
                colorFilter: isDark
                    ? ColorFilter.mode(
                  DuotoneTheme.secondary.withOpacity(0.7),
                  BlendMode.overlay,
                )
                    : ColorFilter.mode(
                  DuotoneTheme.primary.withOpacity(0.5),
                  BlendMode.overlay,
                ),
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.restaurant_menu,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    );
                  },
                ),
              )
                  : Container(
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.restaurant_menu,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
          ),

          // Overlay for text visibility
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe tags
                  if (recipe.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? DuotoneTheme.secondary : DuotoneTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recipe.tags.first,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Recipe title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Recipe info
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.prepTime + recipe.cookTime} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: DuotoneTheme.accent3,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerStatsCard extends StatelessWidget {
  const ShimmerStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DuotoneCard(
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 24,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 14,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerRecipeCard extends StatelessWidget {
  final bool isHorizontal;

  const ShimmerRecipeCard({
    super.key,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isHorizontal) {
      return DuotoneCard(
        padding: EdgeInsets.zero,
        child: Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceVariant,
          highlightColor: theme.colorScheme.surface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 120,
                color: Colors.white,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 40,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DuotoneCard(
      padding: EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 40,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerFeaturedCard extends StatelessWidget {
  const ShimmerFeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant,
      highlightColor: theme.colorScheme.surface,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

