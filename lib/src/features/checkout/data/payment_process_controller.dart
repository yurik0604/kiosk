import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../domain/payment_transaction.dart';
import 'receipt_delivery_service.dart';

final Logger _log = Logger(
  printer: SimplePrinter(printTime: true, colors: false),
);

abstract class PaymentTerminal {
  Stream<PaymentTransaction> charge(double amount);
  Future<void> cancel();
}

class SimulatedPaymentTerminal implements PaymentTerminal {
  SimulatedPaymentTerminal({Random? random}) : _random = random ?? Random();

  final Random _random;
  StreamController<PaymentTransaction>? _controller;
  Timer? _scheduled;

  @override
  Stream<PaymentTransaction> charge(double amount) {
    _controller?.close();
    _scheduled?.cancel();

    final controller = StreamController<PaymentTransaction>();
    _controller = controller;

    final txnId = 'SIM-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    void emit(PaymentTransaction txn) {
      if (!controller.isClosed) controller.add(txn);
    }

    void schedule(Duration delay, void Function() body) {
      _scheduled = Timer(delay, body);
    }

    emit(PaymentTransaction(
      status: PaymentTransactionStatus.waitingForCard,
      transactionId: txnId,
      amount: amount,
    ));

    schedule(const Duration(seconds: 3), () {
      emit(PaymentTransaction(
        status: PaymentTransactionStatus.processing,
        transactionId: txnId,
        amount: amount,
      ));

      schedule(const Duration(seconds: 2), () {
        // Stop at "approved": the post-payment receipt chain (exchange slip →
        // print/SMS delivery) is user-driven from here, orchestrated by the
        // controller, not auto-advanced by the terminal.
        emit(PaymentTransaction(
          status: PaymentTransactionStatus.approved,
          transactionId: txnId,
          amount: amount,
        ));
        controller.close();
      });
    });

    return controller.stream;
  }

  @override
  Future<void> cancel() async {
    _scheduled?.cancel();
    _scheduled = null;
    final controller = _controller;
    if (controller != null && !controller.isClosed) {
      controller.add(const PaymentTransaction(
        status: PaymentTransactionStatus.error,
        message: 'cancelled',
      ));
      await controller.close();
    }
    _controller = null;
  }

  // ignore: unused_element
  void _maybeFail(StreamController<PaymentTransaction> c, String txnId) {
    // Hook for future random-decline simulation.
    if (_random.nextDouble() < 0) {
      c.add(PaymentTransaction(
        status: PaymentTransactionStatus.declined,
        transactionId: txnId,
        message: 'Card declined',
      ));
      c.close();
    }
  }
}

final paymentTerminalProvider = Provider<PaymentTerminal>((ref) {
  final terminal = SimulatedPaymentTerminal();
  ref.onDispose(terminal.cancel);
  return terminal;
});

class PaymentProcessController extends Notifier<PaymentTransaction> {
  StreamSubscription<PaymentTransaction>? _sub;

  @override
  PaymentTransaction build() {
    ref.onDispose(() => _sub?.cancel());
    return const PaymentTransaction();
  }

  Future<void> chargeCard(double amount) async {
    if (state.status != PaymentTransactionStatus.idle &&
        !state.isCompleted &&
        !state.isFailed) {
      return;
    }
    await _sub?.cancel();
    final terminal = ref.read(paymentTerminalProvider);
    _log.i('Payment simulation: starting for $amount');
    _sub = terminal.charge(amount).listen(
      (txn) {
        state = txn;
        _log.d('Payment simulation: ${txn.status}');
      },
      onError: (Object e, StackTrace s) {
        _log.e('Payment simulation error', error: e, stackTrace: s);
        state = state.copyWith(
          status: PaymentTransactionStatus.error,
          message: e.toString(),
        );
      },
    );
  }

  /// Runs the chosen delivery: shows the matching in-flight status
  /// (printingReceipt / sendingSms), awaits the delivery service, then
  /// completes. This is the tail of the post-payment handler chain — the point
  /// where the receipt (and optional exchange slip) is actually produced.
  Future<void> deliverReceipt(
    ReceiptJob job, {
    required ReceiptDelivery delivery,
  }) async {
    // Guard: only valid once payment is approved / while choosing.
    if (!state.isChoosingReceipt && !state.isApproved) return;

    final service = ref.read(receiptDeliveryServiceProvider);
    switch (delivery) {
      case ReceiptDelivery.print:
        state = state.copyWith(
          status: PaymentTransactionStatus.printingReceipt,
        );
        await service.printDocuments(job);
      case ReceiptDelivery.sms:
        state = state.copyWith(status: PaymentTransactionStatus.sendingSms);
        await service.sendSms(job);
    }
    // The delivery may have been cancelled/reset while awaiting.
    if (state.isDelivering) {
      state = state.copyWith(status: PaymentTransactionStatus.completed);
    }
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
    await ref.read(paymentTerminalProvider).cancel();
    state = const PaymentTransaction();
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    state = const PaymentTransaction();
  }
}

final paymentProcessControllerProvider =
    NotifierProvider<PaymentProcessController, PaymentTransaction>(
  PaymentProcessController.new,
);
