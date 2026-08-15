import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../theme/app_theme.dart';

class CategoryPill extends StatelessWidget {
  final ActivityCategory category;
  const CategoryPill({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.categoryColors[category.name] ??
        (AppColors.primaryLight, AppColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.label,
        style: TextStyle(color: colors.$2, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
