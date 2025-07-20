import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bitebuddy/models/pantry_item.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/screens/pantry/add_pantry_item_screen.dart';
import 'package:bitebuddy/screens/pantry/edit_pantry_item_screen.dart';
import 'package:bitebuddy/widgets/elevated_card.dart';
import 'package:bitebuddy/theme/app_theme.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Fruits', 'Vegetables', 'Dairy', 'Meat', 'Grains',
    'Canned Goods', 'Spices', 'Baking', 'Snacks', 'Beverages', 'Other'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;
    final theme = Theme.of(context);

    if (userId == null) {
      return const Center(child: Text('Please sign in to view your pantry'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            itemBuilder: (context) {
              return _categories.map((category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search pantry items...',
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
          if (_selectedCategory != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_selectedCategory),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = 'All';
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pantry_items')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.kitchen_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your pantry is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add items to your pantry to get started',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final pantryItems = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return PantryItem.fromMap(data, doc.id);
                }).toList();

                // Apply category filter
                if (_selectedCategory != 'All') {
                  pantryItems.retainWhere((item) => item.category == _selectedCategory);
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  pantryItems.retainWhere((item) {
                    return item.name.toLowerCase().contains(query) ||
                        item.category.toLowerCase().contains(query);
                  });
                }

                if (pantryItems.isEmpty) {
                  return const Center(child: Text('No items match your search'));
                }

                // Sort by expiry date (items expiring soon first)
                pantryItems.sort((a, b) {
                  if (a.expiryDate == null && b.expiryDate == null) return 0;
                  if (a.expiryDate == null) return 1;
                  if (b.expiryDate == null) return -1;
                  return a.expiryDate!.compareTo(b.expiryDate!);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pantryItems.length,
                  itemBuilder: (context, index) {
                    final item = pantryItems[index];
                    final isExpiringSoon = item.expiryDate != null &&
                        item.expiryDate!.difference(DateTime.now()).inDays <= 3;

                    return ElevatedCard(
                      elevationLevel: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditPantryItemScreen(item: item),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getCategoryColor(item.category),
                            child: Text(
                              item.category.isNotEmpty
                                  ? item.category[0].toUpperCase()
                                  : 'O',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${item.quantity} ${item.unit}'),
                                if (item.expiryDate != null)
                                  Text(
                                    'Expires: ${DateFormat('MMM d, y').format(item.expiryDate!)}',
                                    style: TextStyle(
                                      color: isExpiringSoon ? Colors.red : null,
                                      fontWeight: isExpiringSoon ? FontWeight.bold : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EditPantryItemScreen(item: item),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteConfirmation(item);
                                },
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPantryItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Fruits':
        return Colors.red;
      case 'Vegetables':
        return Colors.green;
      case 'Dairy':
        return Colors.blue;
      case 'Meat':
        return Colors.brown;
      case 'Grains':
        return Colors.amber;
      case 'Canned Goods':
        return Colors.grey;
      case 'Spices':
        return Colors.orange;
      case 'Baking':
        return Colors.pink;
      case 'Snacks':
        return Colors.purple;
      case 'Beverages':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  void _showDeleteConfirmation(PantryItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${item.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('pantry_items')
                    .doc(item.id)
                    .delete();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

