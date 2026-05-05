import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/data/session_controller.dart';
import '../domain/payment_method.dart';

class PaymentState {
  const PaymentState({this.allocations = const {}});

  final Map<PaymentMethod, double> allocations;

  double get allocated =>
      allocations.values.fold(0.0, (sum, value) => sum + value);

  double amountFor(PaymentMethod method) => allocations[method] ?? 0.0;

  bool isActive(PaymentMethod method) => (allocations[method] ?? 0.0) > 0.005;

  PaymentState copyWith({Map<PaymentMethod, double>? allocations}) =>
      PaymentState(allocations: allocations ?? this.allocations);
}

class PaymentController extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();

  double get _total => ref.read(sessionControllerProvider).total;

  double remainingExcluding(PaymentMethod method) {
    final others = state.allocations.entries
        .where((entry) => entry.key != method)
        .fold(0.0, (sum, entry) => sum + entry.value);
    return (_total - others).clamp(0.0, double.infinity);
  }

  double remaining() => (_total - state.allocated).clamp(0.0, double.infinity);

  void setAmount(PaymentMethod method, double amount) {
    final cap = remainingExcluding(method);
    final clamped = amount.clamp(0.0, cap);
    final next = Map<PaymentMethod, double>.from(state.allocations);
    if (clamped <= 0.005) {
      next.remove(method);
    } else {
      next[method] = clamped;
    }
    state = state.copyWith(allocations: next);
  }

  void payRemainingWith(PaymentMethod method) {
    setAmount(method, state.amountFor(method) + remaining());
  }

  void clear(PaymentMethod method) => setAmount(method, 0);

  void reset() => state = const PaymentState();
}

final paymentControllerProvider =
    NotifierProvider<PaymentController, PaymentState>(PaymentController.new);
