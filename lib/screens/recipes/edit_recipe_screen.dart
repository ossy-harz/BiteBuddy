import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:bitebuddy/models/recipe.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/widgets/custom_button.dart';
import 'package:bitebuddy/widgets/custom_text_field.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;
  
  late List<String> _ingredients;
  late List<String> _instructions;
  late List<String> _selectedTags;
  
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  final _picker = ImagePicker();
  
  final List<String> _availableTags = [
    'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack',
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free',
    'Quick', 'Easy', 'Healthy', 'Comfort Food', 'Spicy',
  ];
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description);
    _prepTimeController = TextEditingController(text: widget.recipe.prepTime.toString());
    _cookTimeController = TextEditingController(text: widget.recipe.cookTime.toString());
    _servingsController = TextEditingController(text: widget.recipe.servings.toString());
    
    _ingredients = List.from(widget.recipe.ingredients);
    if (_ingredients.isEmpty) {
      _ingredients.add('');
    }
    
    _instructions = List.from(widget.recipe.instructions);
    if (_instructions.isEmpty) {
      _instructions.add('');
    }
    
    _selectedTags = List.from(widget.recipe.tags);
    _currentImageUrl = widget.recipe.imageUrl;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl;
    
    try {
      final String fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('recipe_images')
          .child('$fileName.jpg');
      
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return _currentImageUrl;
    }
  }
  
  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate ingredients and instructions
    if (_ingredients.length == 1 && _ingredients[0].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }
    
    if (_instructions.length == 1 && _instructions[0].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one instruction')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Upload image if selected
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }
      
      // Filter out empty ingredients and instructions
      final ingredients = _ingredients.where((item) => item.isNotEmpty).toList();
      final instructions = _instructions.where((item) => item.isNotEmpty).toList();
      
      // Update recipe document
      final recipeData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl ?? _currentImageUrl ?? '',
        'ingredients': ingredients,
        'instructions': instructions,
        'tags': _selectedTags,
        'prepTime': int.parse(_prepTimeController.text),
        'cookTime': int.parse(_cookTimeController.text),
        'servings': int.parse(_servingsController.text),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .update(recipeData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating recipe: $e')),
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
        title: const Text('Edit Recipe'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_currentImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: _imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Recipe Photo',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _titleController,
                    labelText: 'Recipe Title',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _prepTimeController,
                          labelText: 'Prep Time (min)',
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
                        child: CustomTextField(
                          controller: _cookTimeController,
                          labelText: 'Cook Time (min)',
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
                        child: CustomTextField(
                          controller: _servingsController,
                          labelText: 'Servings',
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _ingredients[index],
                                decoration: InputDecoration(
                                  hintText: 'Enter ingredient ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _ingredients[index] = value;
                                  
                                  // Add a new empty field if this is the last one and not empty
                                  if (index == _ingredients.length - 1 && value.isNotEmpty) {
                                    setState(() {
                                      _ingredients.add('');
                                    });
                                  }
                                },
                              ),
                            ),
                            if (_ingredients.length > 1 && index < _ingredients.length - 1)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _ingredients.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _instructions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: _instructions[index],
                                decoration: InputDecoration(
                                  hintText: 'Enter step ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  _instructions[index] = value;
                                  
                                  // Add a new empty field if this is the last one and not empty
                                  if (index == _instructions.length - 1 && value.isNotEmpty) {
                                    setState(() {
                                      _instructions.add('');
                                    });
                                  }
                                },
                              ),
                            ),
                            if (_instructions.length > 1 && index < _instructions.length - 1)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _instructions.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    onPressed: _updateRecipe,
                    child: const Text('Update Recipe'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

