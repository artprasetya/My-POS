import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/core/utils/excel_export_service.dart';
import 'package:my_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_pos/features/transactions/data/repositories/transaction_repository.dart';
import 'package:my_pos/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:my_pos/l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<DashboardBloc>().add(DashboardLoadRequested());
    context.read<TransactionBloc>().add(TransactionsLoadRequested(
          startDate: _startDate,
          endDate: _endDate,
        ));
  }

  Future<void> _exportData(AppLocalizations l10n) async {
    setState(() => _isExporting = true);
    try {
      final repo = context.read<TransactionRepository>();
      final txns = await repo.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
        limit: 1000,
      );

      if (mounted) {
        await ExcelExportService.exportTransactions(txns);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange:
                    DateTimeRange(start: _startDate, end: _endDate),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: AppColors.primary,
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
                _loadData();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryGrid(state, l10n),
                const SizedBox(height: AppSizes.xl),
                _buildChartSection(state, isDark, l10n),
                const SizedBox(height: AppSizes.xl),
                _buildBestSellers(state, isDark, l10n),
                const SizedBox(height: AppSizes.xl),
                _buildSalesHistoryHighlight(isDark, l10n),
                const SizedBox(height: AppSizes.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData(l10n),
                    icon: _isExporting
                        ? const SizedBox(
                            width: AppSizes.xl,
                            height: AppSizes.xl,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.file_download_outlined),
                    label: Text(
                      _isExporting
                          ? 'Exporting...'
                          : 'Export Sales Report (.xlsx)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardState state, AppLocalizations l10n) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    double childAspectRatio = 1.35;
    bool isHorizontal = false;

    if (width < 380) {
      crossAxisCount = 1;
      childAspectRatio = 4.2;
      isHorizontal = true;
    } else if (width < 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
      isHorizontal = false;
    } else if (width < 900) {
      crossAxisCount = 3;
      childAspectRatio = 1.45;
      isHorizontal = false;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.45;
      isHorizontal = false;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.md,
      mainAxisSpacing: AppSizes.md,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(l10n.totalRevenue, state.totalRevenue.toCurrency(),
            Icons.payments_outlined, AppColors.primary,
            isHorizontal: isHorizontal),
        _buildStatCard(l10n.orders, state.totalTransactions.toString(),
            Icons.shopping_bag_outlined, Colors.orange,
            isHorizontal: isHorizontal),
        _buildStatCard(
            l10n.productsSold, '124', Icons.inventory_2_outlined, Colors.blue,
            isHorizontal: isHorizontal),
        _buildStatCard(l10n.netProfit, (state.totalRevenue * 0.3).toCurrency(),
            Icons.trending_up_rounded, Colors.green,
            isHorizontal: isHorizontal),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      {bool isHorizontal = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconWidget = Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Icon(icon, color: color, size: AppSizes.iconMd),
    );

    final textWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5)),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: isHorizontal
          ? Row(
              children: [
                iconWidget,
                const SizedBox(width: AppSizes.md),
                Expanded(child: textWidget),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconWidget,
                const Spacer(),
                textWidget,
              ],
            ),
    );
  }

  Widget _buildChartSection(
      DashboardState state, bool isDark, AppLocalizations l10n) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.revenueTrend,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Text(
                  'Past 7 Days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightGray.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: state.dailySales.isEmpty
                        ? [const FlSpot(0, 0)]
                        : state.dailySales
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(),
                                (e.value['total'] as num).toDouble()))
                            .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellers(
      DashboardState state, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bestSellingProducts,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.md),
          if (state.bestSellingProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(
                child: Text(
                  'No sales data available yet',
                  style: TextStyle(color: AppColors.mediumGray, fontSize: 13),
                ),
              ),
            )
          else
            ...state.bestSellingProducts.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Center(
                            child: Icon(Icons.inventory_2_outlined,
                                size: AppSizes.iconMd,
                                color: AppColors.primary)),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${item['total_quantity']} units sold',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.mediumGray)),
                          ],
                        ),
                      ),
                      Text(
                          ((item['total_quantity'] as num) * 15000)
                              .toCurrency(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSalesHistoryHighlight(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    l10n.detailedSalesHistory,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/reports/history'),
                icon: const Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                label: const Icon(Icons.arrow_forward_rounded, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          const Divider(),
          const SizedBox(height: AppSizes.sm),
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              if (state is TransactionsLoaded) {
                final txns = state.transactions;
                if (txns.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
                    child: Center(
                      child: Text(
                        'No transactions recorded yet.',
                        style: TextStyle(
                            color: AppColors.mediumGray, fontSize: 13),
                      ),
                    ),
                  );
                }

                // Show only the 3 most recent transactions
                final recentTxns = txns.take(3).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTxns.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final txn = recentTxns[index];
                    return InkWell(
                      onTap: () => context.push('/reports/history/${txn.id}'),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.sm),
                              decoration: BoxDecoration(
                                color: _getPaymentMethodColor(txn.paymentMethod)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getPaymentMethodIcon(txn.paymentMethod),
                                color:
                                    _getPaymentMethodColor(txn.paymentMethod),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn.transactionNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM dd, HH:mm')
                                        .format(txn.createdAt),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.mediumGray),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  txn.total.toCurrency(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPaymentMethodColor(
                                            txn.paymentMethod)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull),
                                  ),
                                  child: Text(
                                    txn.paymentMethod.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _getPaymentMethodColor(
                                          txn.paymentMethod),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSizes.xs),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.mediumGray, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              if (state is TransactionError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                  child: Center(
                    child: Text(
                      'Failed to load history: ${state.message}',
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
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

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money_rounded;
      case 'qris':
        return Icons.qr_code_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
