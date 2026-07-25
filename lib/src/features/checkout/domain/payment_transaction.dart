enum PaymentTransactionStatus {
  idle,
  waitingForCard,
  processing,
  approved,

  /// Payment succeeded; the shopper is choosing their receipt options
  /// (exchange slip? print or SMS?).
  choosingReceipt,
  declined,

  /// A print job is running (the receipt, and optionally an exchange slip).
  printingReceipt,

  /// An SMS with the receipt (and optional exchange slip) is being sent.
  sendingSms,
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

  /// The shopper is picking receipt options after a successful payment.
  bool get isChoosingReceipt =>
      status == PaymentTransactionStatus.choosingReceipt;

  /// A delivery (print or SMS) is in progress.
  bool get isDelivering =>
      status == PaymentTransactionStatus.printingReceipt ||
      status == PaymentTransactionStatus.sendingSms;

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
