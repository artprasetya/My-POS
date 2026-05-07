import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/transactions/data/repositories/transaction_repository.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart';

// ─── Events ───
abstract class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionsLoadRequested extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? search;

  TransactionsLoadRequested({this.startDate, this.endDate, this.search});

  @override
  List<Object?> get props => [startDate, endDate, search];
}

class TransactionDetailRequested extends TransactionEvent {
  final String transactionId;
  TransactionDetailRequested(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

// ─── States ───
abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionsLoaded extends TransactionState {
  final List<Transaction> transactions;
  TransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionDetailLoaded extends TransactionState {
  final Transaction transaction;
  TransactionDetailLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository;

  TransactionBloc({required TransactionRepository repository})
      : _repository = repository,
        super(TransactionInitial()) {
    on<TransactionsLoadRequested>(_onLoadTransactions);
    on<TransactionDetailRequested>(_onLoadDetail);
  }

  Future<void> _onLoadTransactions(
    TransactionsLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await _repository.getTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
        search: event.search,
      );
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadDetail(
    TransactionDetailRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transaction = await _repository.getTransaction(event.transactionId);
      emit(TransactionDetailLoaded(transaction));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
