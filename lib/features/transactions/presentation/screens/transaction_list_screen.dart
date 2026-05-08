import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/core/widgets/pos_empty_state.dart';
import 'package:my_pos/core/widgets/pos_loading_indicator.dart';
import 'package:my_pos/core/widgets/pos_search_bar.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart';
import 'package:my_pos/features/transactions/presentation/bloc/transaction_bloc.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    context.read<TransactionBloc>().add(TransactionsLoadRequested(
          search: _searchController.text.trim(),
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
        ));
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _searchController.clear();
    });
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: Icon(
              Icons.date_range_rounded,
              color: _selectedDateRange != null ? AppColors.primary : null,
            ),
            tooltip: 'Filter by Date',
          ),
          if (_selectedDateRange != null || _searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_list_off_rounded,
                  color: AppColors.error),
              tooltip: 'Clear Filters',
            ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: PosSearchBar(
              controller: _searchController,
              hintText: 'Search by TXN number...',
              onChanged: (v) => _loadTransactions(),
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, 0, AppSizes.lg, AppSizes.md),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDateRange = null);
                      _loadTransactions();
                    },
                    child: const Icon(Icons.cancel_rounded,
                        size: 18, color: AppColors.mediumGray),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const PosLoadingIndicator(
                      message: 'Fetching history...');
                }

                if (state is TransactionsLoaded) {
                  if (state.transactions.isEmpty) {
                    return PosEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Transactions',
                      subtitle: _searchController.text.isNotEmpty ||
                              _selectedDateRange != null
                          ? 'Try changing your filters'
                          : 'No sales recorded yet',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadTransactions(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      itemCount: state.transactions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSizes.md),
                      itemBuilder: (context, index) {
                        final txn = state.transactions[index];
                        return _TransactionCard(transaction: txn)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 50 * index))
                            .slideX(begin: 0.05);
                      },
                    ),
                  );
                }

                if (state is TransactionError) {
                  return PosEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: state.message,
                    actionText: 'Retry',
                    onAction: _loadTransactions,
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push('/transactions/${transaction.id}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transactionNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm')
                          .format(transaction.createdAt),
                      style: const TextStyle(
                          color: AppColors.mediumGray, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentMethodColor(transaction.paymentMethod)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    transaction.paymentMethod.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPaymentMethodColor(transaction.paymentMethod),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cashier',
                        style: TextStyle(
                            color: AppColors.mediumGray, fontSize: 11),
                      ),
                      Text(
                        transaction.cashierName ?? 'System',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Amount',
                      style:
                          TextStyle(color: AppColors.mediumGray, fontSize: 11),
                    ),
                    Text(
                      transaction.total.toCurrency(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'qris':
        return AppColors.primary;
      case 'card':
        return AppColors.warning;
      default:
        return AppColors.mediumGray;
    }
  }
}
