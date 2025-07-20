import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bitebuddy/models/pantry_item.dart';
import 'package:bitebuddy/widgets/custom_button.dart';
import 'package:bitebuddy/widgets/custom_text_field.dart';

class EditPantryItemScreen extends StatefulWidget {
  final PantryItem item;

  const EditPantryItemScreen({
    super.key,
    required this.item,
  });

  @override
  State<EditPantryItemScreen> createState() => _EditPantryItemScreenState();
}

class _EditPantryItemScreenState extends State<EditPantryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late String _selectedCategory;
  late String _selectedUnit;
  late DateTime? _expiryDate;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Fruits', 'Vegetables', 'Dairy', 'Meat', 'Grains',
    'Canned Goods', 'Spices', 'Baking', 'Snacks', 'Beverages', 'Other'
  ];
  
  final List<String> _units = [
    'pcs', 'g', 'kg', 'ml', 'L', 'tbsp', 'tsp', 'cup', 'oz', 'lb', 'bunch'
  ];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _selectedCategory = widget.item.category;
    _selectedUnit = widget.item.unit;
    _expiryDate = widget.item.expiryDate;
  }
  
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
  
  Future<void> _updatePantryItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pantryItemData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'expiryDate': _expiryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('pantry_items')
          .doc(widget.item.id)
          .update(pantryItemData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
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
        title: const Text('Edit Pantry Item'),
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
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                        suffixIconConstraints: const BoxConstraints(minWidth: 48),
                        suffixIconColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _expiryDate == null
                                ? 'Select Date'
                                : DateFormat('MMM d, y').format(_expiryDate!),
                          ),
                          if (_expiryDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _expiryDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    onPressed: _updatePantryItem,
                    child: const Text('Update Item'),
                  ),
                ],
              ),
            ),
    );
  }
}

