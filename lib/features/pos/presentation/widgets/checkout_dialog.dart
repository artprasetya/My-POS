import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/core/utils/receipt_service.dart';
import 'package:my_pos/features/pos/presentation/bloc/cart_bloc.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart'
    as model;
import 'package:my_pos/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:my_pos/l10n/app_localizations.dart';

class CheckoutDialog extends StatefulWidget {
  final CartState cartState;

  const CheckoutDialog({super.key, required this.cartState});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _paymentMethod = 'cash';
  final _cashController = TextEditingController();
  double _change = 0;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final cash = double.tryParse(_cashController.text) ?? 0;
    setState(() {
      _change = cash - widget.cartState.totalAmount;
    });
  }

  void _onCheckout() {
    context.read<TransactionBloc>().add(
          TransactionCreateRequested(
            items: widget.cartState.items,
            subtotal: widget.cartState.totalAmount,
            discountAmount: 0,
            taxAmount: 0,
            total: widget.cartState.totalAmount,
            paymentMethod: _paymentMethod,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionCreateSuccess) {
          context.read<CartBloc>().add(CartCleared());
          Navigator.pop(context); // Close checkout dialog
          _showReceiptDialog(context, state.transaction, l10n);
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.checkout,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.lg),
              _buildSummary(l10n),
              const SizedBox(height: AppSizes.xl),
              const Text('Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.md),
              _buildPaymentMethods(),
              const SizedBox(height: AppSizes.xl),
              if (_paymentMethod == 'cash') _buildCashInput(),
              const SizedBox(height: AppSizes.xl),
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  final isLoading = state is TransactionLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.checkout),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.extraLightGray,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.total, style: const TextStyle(fontSize: 16)),
          Text(
            widget.cartState.totalAmount.toCurrency(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Row(
      children: [
        _PaymentMethodCard(
          label: 'Cash',
          icon: Icons.money_rounded,
          isSelected: _paymentMethod == 'cash',
          onTap: () => setState(() => _paymentMethod = 'cash'),
        ),
        const SizedBox(width: AppSizes.md),
        _PaymentMethodCard(
          label: 'QRIS',
          icon: Icons.qr_code_rounded,
          isSelected: _paymentMethod == 'qris',
          onTap: () => setState(() => _paymentMethod = 'qris'),
        ),
        const SizedBox(width: AppSizes.md),
        _PaymentMethodCard(
          label: 'Card',
          icon: Icons.credit_card_rounded,
          isSelected: _paymentMethod == 'card',
          onTap: () => setState(() => _paymentMethod = 'card'),
        ),
      ],
    );
  }

  Widget _buildCashInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cash Received',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.sm),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: '0',
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Change', style: TextStyle(fontSize: 16)),
            Text(
              _change < 0 ? 'Rp 0' : _change.toCurrency(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _change < 0 ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showReceiptDialog(
      BuildContext context, dynamic transaction, AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptDialog(transaction: transaction, l10n: l10n),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGray,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.primary : AppColors.mediumGray),
              const SizedBox(height: AppSizes.sm),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.mediumGray,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptDialog extends StatelessWidget {
  final dynamic transaction;
  final AppLocalizations l10n;
  const ReceiptDialog(
      {super.key, required this.transaction, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 64),
            const SizedBox(height: AppSizes.lg),
            Text(
              l10n.paymentSuccessful,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              transaction.transactionNumber,
              style: const TextStyle(color: AppColors.mediumGray),
            ),
            const SizedBox(height: AppSizes.xl),
            const Divider(),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.total, style: const TextStyle(fontSize: 16)),
                Text(
                  (transaction.total as double).toCurrency(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.huge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ReceiptService.generateAndPrint(
                        transaction as model.Transaction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.printReceipt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
