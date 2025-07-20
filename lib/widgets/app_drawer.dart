import 'package:flutter/material.dart';
import 'package:bitebuddy/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/providers/theme_provider.dart';
import 'package:bitebuddy/screens/profile/profile_screen.dart';
import 'package:bitebuddy/screens/recipes/recipes_screen.dart';
import 'package:bitebuddy/screens/meal_planning/meal_planning_screen.dart';
import 'package:bitebuddy/screens/pantry/pantry_screen.dart';
import 'package:bitebuddy/screens/pantry/shopping_list_screen.dart';
import 'package:bitebuddy/screens/community/community_screen.dart';
import 'package:bitebuddy/screens/ai/meal_plan_generator_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<dynamic> navItems;
  final Function(int) onItemSelected;
  final String? userId;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.navItems,
    required this.onItemSelected,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Main navigation section
                    Text(
                      'MAIN NAVIGATION',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDrawerItem(
                      context,
                      icon: Icons.home_rounded,
                      title: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () {
                        onItemSelected(0);
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.menu_book_rounded,
                      title: 'Recipes',
                      isSelected: selectedIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecipesScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Meal Planning',
                      isSelected: selectedIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MealPlanningScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.kitchen_rounded,
                      title: 'Pantry',
                      isSelected: selectedIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PantryScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.shopping_cart_rounded,
                      title: 'Shopping List',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people_rounded,
                      title: 'Community',
                      isSelected: selectedIndex == 4,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CommunityScreen()),
                        );
                      },
                    ),

                    const Divider(height: 32),

                    // AI Features section
                    Text(
                      'AI FEATURES',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDrawerItem(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'AI Recipe Generator',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecipesScreen(initialTab: 1)),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.calendar_month,
                      title: 'AI Meal Planner',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MealPlanGeneratorScreen()),
                        );
                      },
                    ),

                    const Divider(height: 32),

                    // Settings section
                    Text(
                      'SETTINGS',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDrawerItem(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      isSelected: selectedIndex == 5,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: themeProvider.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      title: themeProvider.themeMode == ThemeMode.dark
                          ? 'Dark Mode'
                          : 'Light Mode',
                      isSelected: false,
                      trailing: Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                      onTap: () {
                        themeProvider.toggleTheme();
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout,
                      title: 'Sign Out',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        _showSignOutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // App version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'BiteBuddy v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      color: theme.colorScheme.primary,
                      size: 24,
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
            const SizedBox(height: 16),
            if (userId != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading profile...',
                      style: TextStyle(color: Colors.white70),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      'Welcome!',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final name = userData?['name'] as String? ?? 'User';
                  final email = userData?['email'] as String? ?? '';
                  final avatarUrl = userData?['avatarUrl'] as String? ?? '';

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool isSelected,
        Widget? trailing,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

