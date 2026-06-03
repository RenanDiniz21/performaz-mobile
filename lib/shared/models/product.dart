import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.unitOfMeasure,
    this.code,
    this.category,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double unitPrice;
  final String unitOfMeasure;
  final String? code;
  final String? category;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['unitPrice'] ?? json['unit_price'];
    final rawUnit =
        json['unit'] ?? json['unitOfMeasure'] ?? json['unit_of_measure'];

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      unitPrice: (rawPrice as num).toDouble(),
      unitOfMeasure: rawUnit as String,
      code: json['code'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      isActive:
          json['active'] as bool? ??
          json['isActive'] as bool? ??
          json['is_active'] as bool? ??
          true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit_price': unitPrice,
    'unit_of_measure': unitOfMeasure,
    'code': code,
    'category': category,
    'description': description,
    'image_url': imageUrl,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    unitPrice,
    unitOfMeasure,
    code,
    category,
    isActive,
  ];
}
