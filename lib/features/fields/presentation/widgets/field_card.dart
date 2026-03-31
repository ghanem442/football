import 'package:flutter/material.dart';
import '../../data/models/field_model.dart';

class FieldCard extends StatelessWidget {
  const FieldCard({super.key, required this.field, this.onTap});
  final FieldModel field;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rating = field.averageRating?.toStringAsFixed(1) ?? '-';
    final reviews = field.totalReviews.toString();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.sports_soccer),
        title: Text(field.name),
        subtitle: Text('${field.address}\n⭐ $rating ($reviews)'),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}