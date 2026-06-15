enum PaymentTransactionStatus {
  idle,
  waitingForCard,
  processing,
  approved,
  declined,
  printingReceipt,
  completed,
  error,
}

class PaymentTransaction {
  const PaymentTransaction({
    this.status = PaymentTransactionStatus.idle,
    this.transactionId,
    this.amount = 0,
    this.message,
  });

  final PaymentTransactionStatus status;
  final String? transactionId;
  final double amount;
  final String? message;

  bool get isTerminalStage =>
      status == PaymentTransactionStatus.waitingForCard ||
      status == PaymentTransactionStatus.processing;

  bool get isApproved => status == PaymentTransactionStatus.approved;

  bool get isAwaitingReceipt =>
      status == PaymentTransactionStatus.printingReceipt;

  bool get isCompleted => status == PaymentTransactionStatus.completed;

  bool get isFailed =>
      status == PaymentTransactionStatus.declined ||
      status == PaymentTransactionStatus.error;

  PaymentTransaction copyWith({
    PaymentTransactionStatus? status,
    String? transactionId,
    double? amount,
    String? message,
  }) =>
      PaymentTransaction(
        status: status ?? this.status,
        transactionId: transactionId ?? this.transactionId,
        amount: amount ?? this.amount,
        message: message ?? this.message,
      );
}
