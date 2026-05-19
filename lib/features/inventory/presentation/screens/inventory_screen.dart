import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/widgets/pos_card.dart';
import 'package:my_pos/core/widgets/pos_empty_state.dart';
import 'package:my_pos/core/widgets/pos_loading_indicator.dart';
import 'package:my_pos/features/inventory/domain/models/inventory_log.dart';
import 'package:my_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:my_pos/features/products/domain/models/product.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(InventoryLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<InventoryBloc>().add(InventoryLoadRequested()),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const PosLoadingIndicator(
                message: 'Loading inventory logs...');
          }

          if (state is InventoryLogsLoaded) {
            if (state.logs.isEmpty) {
              return const PosEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No Inventory Data',
                subtitle: 'Your stock movements will appear here',
              );
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<InventoryBloc>().add(InventoryLoadRequested()),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.lg),
                itemCount: state.logs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.md),
                itemBuilder: (context, index) {
                  final log = state.logs[index];
                  return _InventoryLogCard(log: log)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 50 * index))
                      .slideX(begin: 0.05);
                },
              ),
            );
          }

          if (state is InventoryError) {
            return PosEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error loading inventory',
              subtitle: state.message,
              actionText: 'Retry',
              onAction: () =>
                  context.read<InventoryBloc>().add(InventoryLoadRequested()),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdjustmentDialog(context),
        label: const Text('Adjust Stock'),
        icon: const Icon(Icons.add_business_rounded),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _StockAdjustmentDialog(),
    );
  }
}

class _InventoryLogCard extends StatelessWidget {
  final InventoryLog log;
  const _InventoryLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return PosCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: log.isStockIn
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.isStockIn ? Icons.add_rounded : Icons.remove_rounded,
              color: log.isStockIn ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.productName ?? 'Unknown Product',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  log.notes ??
                      (log.isStockIn ? 'Manual Stock In' : 'Manual Stock Out'),
                  style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.isStockIn ? '+' : '-'}${log.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: log.isStockIn ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(log.createdAt),
                style:
                    const TextStyle(color: AppColors.mediumGray, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockAdjustmentDialog extends StatefulWidget {
  const _StockAdjustmentDialog();

  @override
  State<_StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<_StockAdjustmentDialog> {
  Product? _selectedProduct;
  String _type = 'in'; // 'in' or 'out'
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadProductsRequested());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      context.read<InventoryBloc>().add(InventoryAdjustmentRequested(
            productId: _selectedProduct!.id,
            quantity: int.parse(_quantityController.text),
            type: _type,
            reason: _reasonController.text.trim(),
          ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Stock'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Selector
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    return DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration:
                          const InputDecoration(labelText: 'Select Product'),
                      items: state.products.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.name));
                      }).toList(),
                      onChanged: (p) => setState(() => _selectedProduct = p),
                      validator: (v) =>
                          v == null ? 'Please select a product' : null,
                    );
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Adjustment Type
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Stock In'),
                        value: 'in',
                        groupValue: _type,
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Stock Out'),
                        value: 'out',
                        groupValue: _type,
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                  ],
                ),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) <= 0)
                      return 'Invalid quantity';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Reason
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'e.g. Restock, Damage, Correction',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: const Text('Apply Adjustment'),
        ),
      ],
    );
  }
}
