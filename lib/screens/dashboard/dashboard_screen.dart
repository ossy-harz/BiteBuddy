import 'package:flutter/material.dart';
import 'package:bitebuddy/screens/dashboard/home_tab.dart';
import 'package:bitebuddy/screens/recipes/recipes_screen.dart';
import 'package:bitebuddy/screens/meal_planning/meal_planning_screen.dart';
import 'package:bitebuddy/screens/pantry/pantry_screen.dart';
import 'package:bitebuddy/screens/profile/profile_screen.dart';
import 'package:bitebuddy/screens/community/community_screen.dart';
import 'package:bitebuddy/theme/app_theme.dart';
import 'package:bitebuddy/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Main navigation screens
  final List<Widget> _screens = [
    const HomeTab(),
    const RecipesScreen(),
    const MealPlanningScreen(),
    const PantryScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  // Navigation items
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.menu_book_rounded,
      label: 'Recipes',
    ),
    _NavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Meal Plan',
    ),
    _NavItem(
      icon: Icons.kitchen_rounded,
      label: 'Pantry',
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Community',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    // Only show drawer on home tab for small screens
    final showDrawer = isSmallScreen && _selectedIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: showDrawer ? AppDrawer(
        selectedIndex: _selectedIndex,
        navItems: _navItems,
        onItemSelected: _onItemSelected,
        userId: userId,
      ) : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: isSmallScreen ? NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemSelected,
        destinations: _navItems.map((item) =>
            NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
            )
        ).toList(),
      ) : null,
    );
  }
}

// Simple navigation item class
class _NavItem {
  final IconData icon;
  final String label;
  final Widget? badge;

  _NavItem({
    required this.icon,
    required this.label,
    this.badge,
  });
}

