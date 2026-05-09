import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/features/pos/domain/models/cart_item.dart';
import 'package:my_pos/features/pos/presentation/bloc/cart_bloc.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:my_pos/core/widgets/pos_search_bar.dart';
import 'package:my_pos/features/products/domain/models/product.dart';
import 'package:my_pos/features/pos/presentation/widgets/barcode_listener.dart';
import 'package:my_pos/features/pos/presentation/widgets/checkout_dialog.dart';
import 'package:my_pos/features/pos/presentation/widgets/scanner_dialog.dart';
import 'package:my_pos/l10n/app_localizations.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadProductsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pos),
        actions: [
          if (!isTablet)
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () => _showMobileCart(context),
                    ),
                    if (state.items.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${state.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: BarcodeListener(
        child: Row(
          children: [
            // ─── Product Section ───
            Expanded(
              flex: 3,
              child: _buildProductSection(l10n),
            ),

            // ─── Cart Sidebar (Tablet Only) ───
            if (isTablet) const VerticalDivider(width: 1),
            if (isTablet)
              const SizedBox(
                width: 350,
                child: _CartSidebar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PosSearchBar(
                      controller: _searchController,
                      hintText: l10n.searchProducts,
                      onChanged: (v) {
                        context
                            .read<ProductBloc>()
                            .add(ProductLoadProductsRequested(
                              search: v,
                              categoryId: _selectedCategoryId,
                            ));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  IconButton.filled(
                    onPressed: () => _showScanner(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              _buildCategoryFilters(),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state.isLoading && state.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return _ProductGrid(products: state.products);
            },
          ),
        ),
      ],
    );
  }

  void _showScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ScannerDialog(),
    );
  }

  Widget _buildCategoryFilters() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: 'All',
                isSelected: _selectedCategoryId == null,
                onTap: () {
                  setState(() => _selectedCategoryId = null);
                  context
                      .read<ProductBloc>()
                      .add(ProductLoadProductsRequested());
                },
              ),
              ...state.categories.map((cat) => _CategoryChip(
                    label: cat.name,
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () {
                      setState(() => _selectedCategoryId = cat.id);
                      context
                          .read<ProductBloc>()
                          .add(ProductLoadProductsRequested(
                            categoryId: cat.id,
                          ));
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXl)),
          ),
          child: const _CartSidebar(),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.gray,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _PosProductCard(product: product);
      },
    );
  }
}

class _PosProductCard extends StatelessWidget {
  final Product product;
  const _PosProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.read<CartBloc>().add(CartItemAdded(product)),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.extraLightGray,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusLg)),
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.mediumGray))
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    product.price.toCurrency(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSidebar extends StatelessWidget {
  const _CartSidebar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: AppSizes.sm),
                  const Text(
                    'Current Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (state.items.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          context.read<CartBloc>().add(CartCleared()),
                      child: const Text('Clear',
                          style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state.items.isEmpty
                  ? _buildEmptyCart(l10n)
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return BlocBuilder<ProductBloc, ProductState>(
                          builder: (context, productState) {
                            final product = productState.products.cast<Product?>().firstWhere(
                                  (p) => p?.id == item.productId,
                                  orElse: () => null,
                                );
                            return _CartItemTile(item: item, product: product);
                          },
                        );
                      },
                    ),
            ),
            _buildCartSummary(context, state, l10n),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.mediumGray),
          const SizedBox(height: AppSizes.md),
          Text(
            l10n.emptyCart,
            style: const TextStyle(
                color: AppColors.mediumGray, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(
      BuildContext context, CartState state, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: l10n.subtotal, value: state.totalAmount.toCurrency()),
          _SummaryRow(label: '${l10n.tax} (0%)', value: 'Rp 0'),
          const Divider(height: 24),
          _SummaryRow(
            label: l10n.total,
            value: state.totalAmount.toCurrency(),
            isTotal: true,
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.items.isEmpty
                  ? null
                  : () => _showCheckout(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: Text(
                l10n.checkout,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckout(BuildContext context, CartState state) {
    showDialog(
      context: context,
      builder: (context) => CheckoutDialog(cartState: state),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final Product? product;
  const _CartItemTile({required this.item, this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item.unitPrice.toCurrency(),
                    style:
                        const TextStyle(color: AppColors.mediumGray, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () => context
                      .read<CartBloc>()
                      .add(CartUpdateQuantity(item.productId, item.quantity - 1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => context
                      .read<CartBloc>()
                      .add(CartUpdateQuantity(item.productId, item.quantity + 1)),
                ),
              ],
            ),
          ],
        ),
        if (product != null &&
            product!.customPrices != null &&
            product!.customPrices!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.xs),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: item.selectedPriceName,
              hint: const Text('Harga Jual (Standard)', style: TextStyle(fontSize: 12)),
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Harga Jual - ${product!.price.toCurrency()}',
                      style: const TextStyle(fontSize: 12)),
                ),
                ...product!.customPrices!.map((tier) => DropdownMenuItem(
                      value: tier.name,
                      child: Text('${tier.name} - ${tier.price.toCurrency()}',
                          style: const TextStyle(fontSize: 12)),
                    )),
              ],
              onChanged: (val) {
                if (val == null) {
                  // Revert to standard price
                  context.read<CartBloc>().add(
                        CartUpdatePriceTier(item.productId, null, product!.price, 1),
                      );
                } else {
                  final selectedTier = product!.customPrices!.firstWhere((t) => t.name == val);
                  context.read<CartBloc>().add(
                        CartUpdatePriceTier(
                            item.productId, selectedTier.name, selectedTier.price, selectedTier.multiplier),
                      );
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? null : AppColors.mediumGray,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
