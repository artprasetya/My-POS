import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/inventory/data/repositories/inventory_repository.dart';
import 'package:my_pos/features/inventory/domain/models/inventory_log.dart';

// ─── Events ───
abstract class InventoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InventoryLoadRequested extends InventoryEvent {
  final String? productId;
  InventoryLoadRequested({this.productId});

  @override
  List<Object?> get props => [productId];
}

class InventoryAdjustmentRequested extends InventoryEvent {
  final String productId;
  final int quantity;
  final String type;
  final String reason;

  InventoryAdjustmentRequested({
    required this.productId,
    required this.quantity,
    required this.type,
    required this.reason,
  });

  @override
  List<Object?> get props => [productId, quantity, type, reason];
}

// ─── States ───
abstract class InventoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLogsLoaded extends InventoryState {
  final List<InventoryLog> logs;
  InventoryLogsLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

class InventoryAdjustmentSuccess extends InventoryState {}

class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repository;

  InventoryBloc({required InventoryRepository repository})
      : _repository = repository,
        super(InventoryInitial()) {
    on<InventoryLoadRequested>(_onLoadLogs);
    on<InventoryAdjustmentRequested>(_onAdjustStock);
  }

  Future<void> _onLoadLogs(
    InventoryLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final logs = await _repository.getInventoryLogs(productId: event.productId);
      emit(InventoryLogsLoaded(logs));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAdjustStock(
    InventoryAdjustmentRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      await _repository.adjustStock(
        productId: event.productId,
        quantity: event.quantity,
        type: event.type,
        reason: event.reason,
      );
      emit(InventoryAdjustmentSuccess());
      add(InventoryLoadRequested()); // Refresh logs after adjustment
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
