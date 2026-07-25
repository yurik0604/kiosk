import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final Logger _log = Logger(
  printer: SimplePrinter(printTime: true, colors: false),
);

/// How the shopper chose to receive their documents.
enum ReceiptDelivery { print, sms }

/// The set of documents to deliver after a successful payment.
class ReceiptJob {
  const ReceiptJob({
    required this.transactionId,
    required this.amount,
    this.includeExchangeSlip = false,
    this.phone,
  });

  /// Reference of the approved payment, printed / referenced on the receipt.
  final String? transactionId;
  final double amount;

  /// Whether to also produce an exchange slip (a price-less gift receipt for
  /// returns/exchanges) alongside the payment receipt.
  final bool includeExchangeSlip;

  /// Destination phone number for SMS delivery. Ignored for print.
  final String? phone;
}

/// Delivers receipts (and optional exchange slips) either by printing at the
/// kiosk or by sending an SMS. Modeled as an interface with a simulated
/// implementation, mirroring [PaymentTerminal] — a real printer/SMS backend can
/// be dropped in behind the same seam later.
abstract class ReceiptDeliveryService {
  /// Prints the receipt (and exchange slip if requested). Completes when the
  /// print job finishes.
  Future<void> printDocuments(ReceiptJob job);

  /// Sends the receipt (and exchange slip if requested) by SMS to [job.phone].
  /// Completes when the message has been dispatched.
  Future<void> sendSms(ReceiptJob job);
}

/// A simulated delivery service: a timed delay standing in for real hardware /
/// gateway calls, so the UI animation has something to await.
class SimulatedReceiptDeliveryService implements ReceiptDeliveryService {
  const SimulatedReceiptDeliveryService();

  @override
  Future<void> printDocuments(ReceiptJob job) async {
    _log.i(
      'Receipt: printing (exchangeSlip=${job.includeExchangeSlip}) '
      'for ${job.transactionId}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    _log.d('Receipt: print complete');
  }

  @override
  Future<void> sendSms(ReceiptJob job) async {
    _log.i(
      'Receipt: sending SMS to ${job.phone} '
      '(exchangeSlip=${job.includeExchangeSlip}) for ${job.transactionId}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    _log.d('Receipt: SMS sent');
  }
}

final receiptDeliveryServiceProvider = Provider<ReceiptDeliveryService>(
  (ref) => const SimulatedReceiptDeliveryService(),
);
