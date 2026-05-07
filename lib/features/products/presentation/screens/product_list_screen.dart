import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/core/widgets/pos_empty_state.dart';
import 'package:my_pos/core/widgets/pos_loading_indicator.dart';
import 'package:my_pos/core/widgets/pos_search_bar.dart';
import 'package:my_pos/features/products/domain/models/product.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategoryId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadProductsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ProductBloc>().add(ProductLoadProductsRequested(
          search: query, categoryId: _selectedCategoryId));
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    context.read<ProductBloc>().add(ProductLoadProductsRequested(
          categoryId: categoryId, search: _searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () => context.push('/products/categories'),
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
          ),
          IconButton(
            onPressed: () => context.push('/products/add'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 18),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  PosSearchBar(
                    controller: _searchController,
                    hintText: 'Search products...',
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _buildCategoryChips(),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state.isLoading && state.products.isEmpty) {
                    return const PosLoadingIndicator(message: 'Loading products...');
                  }
                  
                  if (state.products.isEmpty) {
                    return PosEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Products Found',
                      subtitle: state.searchQuery != null || state.selectedCategoryId != null
                          ? 'Try adjusting your filters'
                          : 'Add your first product to get started',
                      actionText: 'Add Product',
                      onAction: () => context.push('/products/add'),
                    );
                  }
                  
                  return _buildProductGrid(state.products);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final categories = state.categories;
        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildChip('All', null),
              ...categories.map((cat) => _buildChip(cat.name, cat.id)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(categoryId),
        selectedColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.md,
          mainAxisSpacing: AppSizes.md,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: products[index])
              .animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.05);
        },
      );
    });
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/products/edit/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.extraLightGray,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
                        child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder()),
                      )
                    : _placeholder(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (product.categoryName != null)
                      Text(product.categoryName!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontSize: 11)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(product.price.toCurrency(), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.isOutOfStock ? AppColors.errorLight : product.isLowStock ? AppColors.warningLight : AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text('${product.stock}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: product.isOutOfStock ? AppColors.error : product.isLowStock ? AppColors.warning : AppColors.success)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.mediumGray.withValues(alpha: 0.5)));
}
