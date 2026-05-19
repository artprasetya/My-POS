import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/core/widgets/pos_card.dart';
import 'package:my_pos/core/widgets/pos_loading_indicator.dart';
import 'package:my_pos/core/utils/receipt_service.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart';
import 'package:my_pos/features/transactions/presentation/bloc/transaction_bloc.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<TransactionBloc>()
        .add(TransactionDetailRequested(widget.transactionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        actions: [
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionDetailLoaded) {
                return IconButton(
                  onPressed: () =>
                      ReceiptService.generateAndPrint(state.transaction),
                  icon: const Icon(Icons.print_rounded),
                  tooltip: 'Print Receipt',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const PosLoadingIndicator(message: 'Loading details...');
          }

          if (state is TransactionDetailLoaded) {
            final txn = state.transaction;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  _buildHeader(txn),
                  const SizedBox(height: AppSizes.xl),
                  _buildItemList(txn),
                  const SizedBox(height: AppSizes.xl),
                  _buildSummary(txn),
                  const SizedBox(height: AppSizes.huge),
                   Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => ReceiptService.shareReceipt(txn),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySurface,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => ReceiptService.sendToWhatsApp(txn),
                            icon: const Icon(Icons.message_rounded),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          if (state is TransactionError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(Transaction txn) {
    return PosCard(
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 48),
          const SizedBox(height: AppSizes.md),
          const Text(
            'Payment Successful',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            txn.transactionNumber,
            style: const TextStyle(
                color: AppColors.mediumGray, fontWeight: FontWeight.w500),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Divider(),
          ),
          _DetailRow(
              label: 'Date',
              value: DateFormat('MMM dd, yyyy • HH:mm').format(txn.createdAt)),
          const SizedBox(height: AppSizes.sm),
          _DetailRow(label: 'Cashier', value: txn.cashierName ?? 'System'),
          const SizedBox(height: AppSizes.sm),
          _DetailRow(
            label: 'Payment Method',
            value: txn.paymentMethod.toUpperCase(),
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(Transaction txn) {
    return PosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Order Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txn.items.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, indent: AppSizes.lg, endIndent: AppSizes.lg),
            itemBuilder: (context, index) {
              final item = txn.items[index];
              return ListTile(
                title: Text(item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle:
                    Text('${item.quantity} x ${item.unitPrice.toCurrency()}'),
                trailing: Text(item.subtotal.toCurrency(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Transaction txn) {
    return PosCard(
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: txn.subtotal.toCurrency()),
          const SizedBox(height: AppSizes.sm),
          _SummaryRow(
              label: 'Discount',
              value: '- ${txn.discountAmount.toCurrency()}',
              valueColor: AppColors.error),
          if (txn.taxAmount > 0) ...[
            const SizedBox(height: AppSizes.sm),
            _SummaryRow(label: 'Tax', value: txn.taxAmount.toCurrency()),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Divider(),
          ),
          _SummaryRow(
            label: 'Total Amount',
            value: txn.total.toCurrency(),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mediumGray)),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
            color: valueColor ?? (isTotal ? AppColors.primary : null),
          ),
        ),
      ],
    );
  }
}
