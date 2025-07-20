import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final DateTime? expiryDate;
  final DateTime addedDate;
  final bool isLowStock;
  
  PantryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.addedDate,
    this.isLowStock = false,
  });
  
  factory PantryItem.fromMap(Map<String, dynamic> map, String id) {
    return PantryItem(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
      expiryDate: map['expiryDate'] != null 
          ? (map['expiryDate'] as Timestamp).toDate() 
          : null,
      addedDate: (map['addedDate'] as Timestamp).toDate(),
      isLowStock: map['isLowStock'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate,
      'addedDate': addedDate,
      'isLowStock': isLowStock,
    };
  }
  
  PantryItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? addedDate,
    bool? isLowStock,
  }) {
    return PantryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate ?? this.addedDate,
      isLowStock: isLowStock ?? this.isLowStock,
    );
  }
}

