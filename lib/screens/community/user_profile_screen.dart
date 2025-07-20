import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/models/recipe.dart';
import 'package:bitebuddy/widgets/recipe_card.dart';
import 'package:bitebuddy/screens/recipes/recipe_details_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;

    if (currentUserId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      final following = List<String>.from(userData?['following'] ?? []);

      if (mounted) {
        setState(() {
          _isFollowing = following.contains(widget.userId);
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;

    if (currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final following = List<String>.from(userData?['following'] ?? []);

        if (_isFollowing) {
          following.remove(widget.userId);
        } else {
          following.add(widget.userId);
        }

        await userRef.update({'following': following});

        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;
    final isCurrentUser = currentUserId == widget.userId;

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] as String? ?? 'Unknown';
          final avatarUrl = userData['avatarUrl'] as String? ?? '';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(name),
                  background: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40),
                        ) : null,
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (!isCurrentUser)
                    _isLoading
                        ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : IconButton(
                      icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                      onPressed: _toggleFollow,
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Recipes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .where('authorId', isEqualTo: widget.userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No recipes found')),
                    );
                  }

                  final recipes = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Recipe.fromMap(data, doc.id);
                  }).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final recipe = recipes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
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
                        childCount: recipes.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

