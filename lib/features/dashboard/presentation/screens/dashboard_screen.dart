import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/extensions/number_extensions.dart';
import 'package:my_pos/core/widgets/pos_card.dart';
import 'package:my_pos/core/widgets/pos_loading_indicator.dart';
import 'package:my_pos/core/widgets/pos_stat_card.dart';
import 'package:my_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              'Business overview',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<DashboardBloc>().add(DashboardLoadRequested());
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.isLoading && state.todaySales == 0) {
            return const PosLoadingIndicator(message: 'Loading dashboard...');
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(DashboardLoadRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Stat Cards ───
                  _buildStatCards(context, state),
                  const SizedBox(height: AppSizes.xxl),

                  // ─── Sales Chart ───
                  _buildSalesChart(context, state),
                  const SizedBox(height: AppSizes.xxl),

                  // ─── Best Selling Products ───
                  _buildBestSellers(context, state),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.md,
          mainAxisSpacing: AppSizes.md,
          childAspectRatio: childAspectRatio,
          children: [
            PosStatCard(
              title: "Today's Sales",
              value: state.todaySales.toCurrency(),
              icon: Icons.today_rounded,
              iconColor: AppColors.success,
              iconBgColor: AppColors.successLight,
              subtitle: '${state.todayCount} transactions',
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            PosStatCard(
              title: 'Weekly Sales',
              value: state.weeklySales.toCurrency(),
              icon: Icons.calendar_view_week_rounded,
              iconColor: AppColors.info,
              iconBgColor: AppColors.infoLight,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            PosStatCard(
              title: 'Monthly Sales',
              value: state.monthlySales.toCurrency(),
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.warning,
              iconBgColor: AppColors.warningLight,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            PosStatCard(
              title: 'Total Revenue',
              value: state.totalRevenue.toCurrency(),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primarySurface,
              subtitle: '${state.totalTransactions} total transactions',
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        );
      },
    );
  }

  Widget _buildSalesChart(BuildContext context, DashboardState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Trend',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Last 7 days',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.xxl),
          SizedBox(
            height: 200,
            child: state.dailySales.isEmpty
                ? const Center(child: Text('No data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(state.dailySales),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.toCurrency(),
                              TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toCompact(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.gray,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < state.dailySales.length) {
                                final date =
                                    state.dailySales[index]['date'] as String;
                                final parts = date.split('-');
                                return Text(
                                  '${parts[2]}/${parts[1]}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.gray,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxY(state.dailySales) / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightGray,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: state.dailySales.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['total'] as num).toDouble(),
                              gradient: AppColors.primaryGradient,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms);
  }

  Widget _buildBestSellers(BuildContext context, DashboardState state) {
    return PosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best Selling Products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.lg),
          if (state.bestSellingProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.xxl),
              child: Center(child: Text('No data available')),
            )
          else
            ...state.bestSellingProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.categoryColors[
                        index % AppColors.categoryColors.length]
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.categoryColors[
                            index % AppColors.categoryColors.length],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  product['product_name'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Text(
                  '${product['total_quantity']} sold',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100;
    final maxVal = data
        .map((e) => (e['total'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 100 : maxVal * 1.2;
  }
}
