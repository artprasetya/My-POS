import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/features/products/domain/models/category.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadCategoriesRequested());
  }

  void _showAddEditCategoryDialog([Category? category]) {
    final nameController = TextEditingController(text: category?.name);
    final descriptionController = TextEditingController(text: category?.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newCategory = Category(
                  id: category?.id ?? '',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  createdAt: category?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                if (category == null) {
                  context.read<ProductBloc>().add(ProductCreateCategoryRequested(newCategory));
                } else {
                  context.read<ProductBloc>().add(ProductUpdateCategoryRequested(newCategory));
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            onPressed: () => _showAddEditCategoryDialog(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.categories.isEmpty) {
            return const Center(child: Text('No categories yet.'));
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: state.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return ListTile(
                title: Text(category.name),
                subtitle: Text(category.description ?? 'No description'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showAddEditCategoryDialog(category),
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<ProductBloc>().add(ProductDeleteCategoryRequested(category.id));
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    ),
                  ],
                ),
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
