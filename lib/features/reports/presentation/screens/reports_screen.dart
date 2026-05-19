import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/utils/excel_export_service.dart';
import 'package:my_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_pos/features/transactions/data/repositories/transaction_repository.dart';
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

  late NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currencyFormat = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol:
          Localizations.localeOf(context).languageCode == 'id' ? 'Rp ' : ' ',
      decimalDigits: 0,
    );
  }

  void _loadData() {
    context.read<DashboardBloc>().add(DashboardLoadRequested());
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
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded,
                      color: AppColors.primary),
                  title: Text(l10n.detailedSalesHistory),
                  subtitle: const Text('View every transaction and receipt'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/reports/history'),
                ),
                const SizedBox(height: AppSizes.xl),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.touchTargetLg,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData(l10n),
                    icon: _isExporting
                        ? const SizedBox(
                            width: AppSizes.xl,
                            height: AppSizes.xl,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.file_download_outlined),
                    label: Text(_isExporting
                        ? 'Exporting...'
                        : '${l10n.exportToExcel} (.xlsx)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.md,
      mainAxisSpacing: AppSizes.md,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
            l10n.totalRevenue,
            _currencyFormat.format(state.totalRevenue),
            Icons.payments_outlined,
            AppColors.primary),
        _buildStatCard(l10n.orders, state.totalTransactions.toString(),
            Icons.shopping_bag_outlined, Colors.orange),
        _buildStatCard(
            l10n.productsSold, '124', Icons.inventory_2_outlined, Colors.blue),
        _buildStatCard(
            l10n.netProfit,
            _currencyFormat.format(state.totalRevenue * 0.3),
            Icons.trending_up_rounded,
            Colors.green),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),
          const Spacer(),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.mediumGray)),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartSection(
      DashboardState state, bool isDark, AppLocalizations l10n) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.revenueTrend,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.xl),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
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
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
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
            color: isDark ? AppColors.darkBorder : AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bestSellingProducts,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.md),
          ...state.bestSellingProducts.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.massive / 1.6, // ~40
                      height: AppSizes.massive / 1.6,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Center(
                          child: Icon(Icons.inventory_2_outlined,
                              size: AppSizes.iconMd, color: AppColors.primary)),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['product_name'] as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${item['total_quantity']} units sold',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.mediumGray)),
                        ],
                      ),
                    ),
                    Text(
                        _currencyFormat
                            .format((item['total_quantity'] as num) * 15000),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
