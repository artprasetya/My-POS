import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/transactions/data/repositories/transaction_repository.dart';

// ─── Events ───
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {}

// ─── State ───
class DashboardState extends Equatable {
  final bool isLoading;
  final double todaySales;
  final double weeklySales;
  final double monthlySales;
  final double totalRevenue;
  final int todayCount;
  final int totalTransactions;
  final List<Map<String, dynamic>> dailySales;
  final List<Map<String, dynamic>> bestSellingProducts;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.todaySales = 0,
    this.weeklySales = 0,
    this.monthlySales = 0,
    this.totalRevenue = 0,
    this.todayCount = 0,
    this.totalTransactions = 0,
    this.dailySales = const [],
    this.bestSellingProducts = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    double? todaySales,
    double? weeklySales,
    double? monthlySales,
    double? totalRevenue,
    int? todayCount,
    int? totalTransactions,
    List<Map<String, dynamic>>? dailySales,
    List<Map<String, dynamic>>? bestSellingProducts,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      todaySales: todaySales ?? this.todaySales,
      weeklySales: weeklySales ?? this.weeklySales,
      monthlySales: monthlySales ?? this.monthlySales,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      todayCount: todayCount ?? this.todayCount,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      dailySales: dailySales ?? this.dailySales,
      bestSellingProducts: bestSellingProducts ?? this.bestSellingProducts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading, todaySales, weeklySales, monthlySales,
        totalRevenue, todayCount, totalTransactions,
        dailySales, bestSellingProducts, error,
      ];
}

// ─── Bloc ───
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TransactionRepository _repository;

  DashboardBloc({required TransactionRepository repository})
      : _repository = repository,
        super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getDashboardData();
      final dailySales = await _repository.getDailySales();
      final bestSellers = await _repository.getBestSellingProducts();

      emit(state.copyWith(
        isLoading: false,
        todaySales: data['today_sales'] as double,
        weeklySales: data['weekly_sales'] as double,
        monthlySales: data['monthly_sales'] as double,
        totalRevenue: data['total_revenue'] as double,
        todayCount: data['today_count'] as int,
        totalTransactions: data['total_transactions'] as int,
        dailySales: dailySales,
        bestSellingProducts: bestSellers,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
