import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/widgets/custom_button.dart';
import 'package:bitebuddy/widgets/custom_text_field.dart';

class AddPantryItemScreen extends StatefulWidget {
  const AddPantryItemScreen({super.key});

  @override
  State<AddPantryItemScreen> createState() => _AddPantryItemScreenState();
}

class _AddPantryItemScreenState extends State<AddPantryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedCategory = 'Other';
  String _selectedUnit = 'pcs';
  DateTime? _expiryDate;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Fruits', 'Vegetables', 'Dairy', 'Meat', 'Grains',
    'Canned Goods', 'Spices', 'Baking', 'Snacks', 'Beverages', 'Other'
  ];
  
  final List<String> _units = [
    'pcs', 'g', 'kg', 'ml', 'L', 'tbsp', 'tsp', 'cup', 'oz', 'lb', 'bunch'
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  Future<void> _selectExpiryDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate != null) {
      setState(() {
        _expiryDate = pickedDate;
      });
    }
  }
  
  Future<void> _savePantryItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser!.uid;
      
      final pantryItemData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'expiryDate': _expiryDate,
        'addedDate': FieldValue.serverTimestamp(),
        'isLowStock': false,
      };
      
      await FirebaseFirestore.instance
          .collection('pantry_items')
          .add(pantryItemData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to pantry')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
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
        title: const Text('Add Pantry Item'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Item Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _quantityController,
                          labelText: 'Quantity',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: _units.map((unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedUnit = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectExpiryDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _expiryDate == null
                            ? 'Select Date'
                            : DateFormat('MMM d, y').format(_expiryDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    onPressed: _savePantryItem,
                    child: const Text('Add to Pantry'),
                  ),
                ],
              ),
            ),
    );
  }
}

